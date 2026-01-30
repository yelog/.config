---
name: backend
description: MOSS's architectural backend and design principles
---

# backend

The backend architecture uses the `SpringCloud Alibaba` microservice architecture, adopts `Mybatis+Mybatis-Plus` as the ORM framework, `Nacos` as the configuration center and service discovery component, and `Feign` as the component for inter-service calls.

## 模块命名及目录结构

MOSS 的每个微服务模块通常遵循以下目录结构, 其中 `{module-name}` 代表具体的模块名称，如 `common`、`mes-api` 等
```bash
moss-service-{module-name}
├── devops-ci.yml
├── moss-service-{module-name}-common
├── moss-service-{module-name}-server

```

其中 `moss-service-{module-name}-common` 模块用于存放实体类、DTO、VO 、Feign 接口等公共代码。目录结构如下， 其中 {module-name} 代表具体的模块名称，如 `common`、`mes-api` 等}
```bash
src/main/java/com/lenovo/moss/service/{module-name}/
├── annotation     # Stores custom annotation classes
├── constant       # Stores constant definitions used across the project
├── entity         # Stores entity classes
├── enums          # Stores enumeration classes
├── feign          # Stores Feign interface definitions for inter-service communication
├── util           # Stores utility classes
└── vo             # Stores View Object (VO) classes
```

其中 `moss-service-{module-name}-server` 模块用于存放具体的业务逻辑实现，包括控制器、服务层、持久层等。 目录结构如下， 其中 {module-name} 代表具体的模块名称，如 `common`、`mes-api` 等}
```bash
src/main/java/com/lenovo/moss/service/{module-name}/server/
├── config          # Stores configuration classes (such as Spring configuration, property files etc.)
├── controller      # Stores controller classes responsible for handling HTTP requests
├── feign           # Stores Feign client interface definitions for inter-service calls
├── mapper          # Stores MyBatis Mapper (DAO) interfaces for persistence operations
├── MossServiceCommonServerApplication.java  # Main application start-up class for the module
├── service         # Stores service layer classes encapsulating business logic
└── utils           # Stores utility/helper classes used throughout the project
```

## Entity Classes

Entity classes for the `tools` database are created in the `moss-cloud/moss-service-common/moss-service-common-common/` 的 maven 模块的 entity 目录下.

如果不是 `tools` 数据的实体类，当前目录下又有多个微服务，则需要提示用户选择具体的微服务模块.

如果没有 entity 目录需要手动创建, 请参考 [模块命名及目录结构](#模块命名及目录结构)

They need to extend the `BaseEntity` class. Refer to the following template, which requires complete comments. The author should be the current git username, and the date should be the current date.


```java
package com.lenovo.moss.service.common.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.lenovo.moss.framework.core.base.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

/**
 * Test Page Table
 *
 * @author moss
 * @date 2026/01/30
 */
@Data
@EqualsAndHashCode(callSuper = true)
@Accessors(chain = true)
@TableName("test_page")
public class TestPage extends BaseEntity<Long> {

    /**
     * Title
     */
    private String title;

    /**
     * Name
     */
    private String name;

    /**
     * Content
     */
    private String content;

}
```

## ORM Layer

持久层在实体类所在 `maven` 模块的同级 `moss-service-{module-name}-server` 模块下有两个文件，分别是 `{entity-name}Mapper.java` 和 `{entity-name}Mapper.xml`, 其中 `{entity-name}` 为实体类名称.

`{entity-name}Mapper.java` 文件在 `src/main/java/com/lenovo/moss/service/{module-name}/server/mapper` 目录下, 继承 `BaseMapper<T>` 接口, 其中 `T` 为实体类类型. 例如:

```java
package com.lenovo.moss.service.common.server.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.lenovo.moss.framework.core.util.PageVo;
import com.lenovo.moss.service.common.entity.SysRole;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 角色持久层
 *
 * @author Yujie Yang
 * @date 2026/1/30 17:18
 */
@Mapper
public interface SysRoleMapper extends BaseMapper<SysRole> {

    PageVo<SysRole> dataPage(PageVo<SysRole> pageVo, @Param("entity") SysRole entity);
}
```

`{entity-name}Mapper.xml` 文件在 `src/main/resources/mapper/{module-name}` 目录下, 用于编写自定义的 SQL 语句. 例如:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.lenovo.moss.service.common.server.mapper.SysRoleMapper">
    <select id="dataPage" resultType="com.lenovo.moss.service.common.entity.SysRole">
        select sr.id,
               sr.name,
               sr.type,
               sr.description,
               sr.code,
               array_to_string(array_agg(distinct rm.menu_id), ',')    menu_ids,
               array_to_string(array_agg(distinct srt.tenant_id), ',') tenant_ids,
               sr.create_time,
               sr.create_user
        from sys_role sr
                 left join sys_role_menu rm on sr.id = rm.ROLE_ID
                 left join sys_role_tenant srt on srt.menu_id = 0 and sr.id = srt.role_id
        <where>
            <if test="entity != null">
                <if test="entity.name != null and entity.name != ''">
                    and sr.name like concat('%', #{entity.name}, '%')
                </if>
            </if>
        </where>
        group by sr.id, sr.name, sr.type, sr.description
        order by sr.id
    </select>
</mapper>
```

## Service Layer

`Service` 层在 `moss-service-{module-name}-server` 模块的 `src/main/java/com/lenovo/moss/service/{module-name}/server/service` 目录下. 通常包含两个文件, 分别是 `{EntityName}Service.java` 和 `{EntityName}ServiceImpl.java`, 其中 `{EntityName}` 为实体类名称.

`{EntityName}Service.java` 文件定义服务接口, 例如:

```java
package com.lenovo.moss.service.common.server.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.lenovo.moss.framework.core.util.PageVo;
import com.lenovo.moss.service.common.entity.SysRole;

/**
 * 角色service
 *
 * @author yangyj13
 * @date 2019/12/31 16:35
 */
public interface SysRoleService extends IService<SysRole> {
    PageVo<SysRole> dataPage(PageVo<SysRole> pageVo, SysRole entity);
}
```

`{EntityName}ServiceImpl.java` 文件实现服务接口, 例如:

```java
package com.lenovo.moss.service.common.server.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.lenovo.moss.framework.core.util.PageVo;
import com.lenovo.moss.service.common.entity.SysRole;
import com.lenovo.moss.service.common.server.dao.SysRoleMapper;
import com.lenovo.moss.service.common.server.service.SysRoleService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * 系统角色业务层
 *
 * @author yangyj13
 * @date 2019/12/27 16:04
 */
@Service
@RequiredArgsConstructor
public class SysRoleServiceImpl extends ServiceImpl<SysRoleMapper, SysRole> implements SysRoleService {

    @Override
    public PageVo<SysRole> dataPage(PageVo<SysRole> pageVo, SysRole entity) {
        return baseMapper.dataPage(pageVo, entity);
    }
}
```

## Controller Layer

`Controller` 层在 `moss-service-{module-name}-server` 模块的 `src/main/java/com/lenovo/moss/service/{module-name}/server/controller` 目录下. 
- 控制器类通常使用 `@RestController` 注解标注, 并通过 `@RequestMapping` 注解定义请求路径.
- 控制器方法使用 `@GetMapping`、`@PostMapping` 等注解定义具体的 HTTP 请求方法和路径.
- 控制器类可以通过 `@PreAuthorize` 注解实现权限控制.
- 控制器方法通常返回 `ResultData<T>` 类型的响应, 其中 `T` 为具体的数据类型.
- 控制器方法可以使用 `@RequestBody` 注解接收请求体中的数据.
- 控制器类通过 `@Resource` 注解注入服务层接口.

```java
package com.lenovo.moss.service.common.server.controller;

import com.lenovo.moss.framework.core.util.PageVo;
import com.lenovo.moss.framework.core.util.ResultData;
import com.lenovo.moss.service.common.entity.SysRole;
import com.lenovo.moss.service.common.server.service.SysRoleService;
import jakarta.annotation.Resource;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/sysRole")
@PreAuthorize("hasAnyCustomAuthority('common:sysRole')")
public class SysRoleController {


    @Resource
    private SysRoleService sysRoleService;

    @PostMapping("/dataPage")
    public ResultData<PageVo<SysRole>> dataPage(@RequestBody PageVo<SysRole> pageVo) {
        return ResultData.succeed(sysRoleService.dataPage(pageVo, pageVo.getEntity()));
    }
}
```




