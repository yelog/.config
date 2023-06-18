// ==UserScript==
// @name         bilibili
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       You
// @match        https://www.bilibili.com/video/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=bilibili.com
// @grant        none
// ==/UserScript==

(function() {
    'use strict';
document.addEventListener('keydown', function(event) {
  if (event.ctrlKey && event.key === 'f') {
    document.querySelector('.bpx-player-ctrl-full').click()
  }
});
    // Your code here...
})();