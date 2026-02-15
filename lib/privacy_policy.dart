import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const htmlContent = r'''
<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"/><title>Privacy policy</title><style>
/* cspell:disable-file */
/* webkit printing magic: print all background colors */
html {
  -webkit-print-color-adjust: exact;
}
* {
  box-sizing: border-box;
  -webkit-print-color-adjust: exact;
}

html,
body {
  margin: 0;
  padding: 0;
}
@media only screen {
  body {
    margin: 2em auto;
    max-width: 900px;
    color: rgb(55, 53, 47);
  }
}

body {
  line-height: 1.5;
  white-space: pre-wrap;
}

a,
a.visited {
  color: inherit;
  text-decoration: underline;
}

.pdf-relative-link-path {
  font-size: 80%;
  color: #444;
}

h1,
h2,
h3 {
  letter-spacing: -0.01em;
  line-height: 1.2;
  font-weight: 600;
  margin-bottom: 0;
}

.page-title {
  font-size: 2.5rem;
  font-weight: 700;
  margin-top: 0;
  margin-bottom: 0.75em;
}

h1 {
  font-size: 1.875rem;
  margin-top: 1.875rem;
}

h2 {
  font-size: 1.5rem;
  margin-top: 1.5rem;
}

h3 {
  font-size: 1.25rem;
  margin-top: 1.25rem;
}

.source {
  border: 1px solid #ddd;
  border-radius: 3px;
  padding: 1.5em;
  word-break: break-all;
}

.callout {
  border-radius: 10px;
  padding: 1rem;
}

figure {
  margin: 1.25em 0;
  page-break-inside: avoid;
}

figcaption {
  opacity: 0.5;
  font-size: 85%;
  margin-top: 0.5em;
}

mark {
  background-color: transparent;
}

.indented {
  padding-left: 1.5em;
}

hr {
  background: transparent;
  display: block;
  width: 100%;
  height: 1px;
  visibility: visible;
  border: none;
  border-bottom: 1px solid rgba(55, 53, 47, 0.09);
}

img {
  max-width: 100%;
}

@media only print {
  img {
    max-height: 100vh;
    object-fit: contain;
  }
}

@page {
  margin: 1in;
}

.collection-content {
  font-size: 0.875rem;
}

.collection-content td {
  white-space: pre-wrap;
  word-break: break-word;
}

.column-list {
  display: flex;
  justify-content: space-between;
}

.column {
  padding: 0 1em;
}

.column:first-child {
  padding-left: 0;
}

.column:last-child {
  padding-right: 0;
}

.table_of_contents-item {
  display: block;
  font-size: 0.875rem;
  line-height: 1.3;
  padding: 0.125rem;
}

.table_of_contents-indent-1 {
  margin-left: 1.5rem;
}

.table_of_contents-indent-2 {
  margin-left: 3rem;
}

.table_of_contents-indent-3 {
  margin-left: 4.5rem;
}

.table_of_contents-link {
  text-decoration: none;
  opacity: 0.7;
  border-bottom: 1px solid rgba(55, 53, 47, 0.18);
}

table,
th,
td {
  border: 1px solid rgba(55, 53, 47, 0.09);
  border-collapse: collapse;
}

table {
  border-left: none;
  border-right: none;
}

th,
td {
  font-weight: normal;
  padding: 0.25em 0.5em;
  line-height: 1.5;
  min-height: 1.5em;
  text-align: left;
}

th {
  color: rgba(55, 53, 47, 0.6);
}

ol,
ul {
  margin: 0;
  margin-block-start: 0.6em;
  margin-block-end: 0.6em;
}

li > ol:first-child,
li > ul:first-child {
  margin-block-start: 0.6em;
}

ul > li {
  list-style: disc;
}

ul.to-do-list {
  padding-inline-start: 0;
}

ul.to-do-list > li {
  list-style: none;
}

.to-do-children-checked {
  text-decoration: line-through;
  opacity: 0.375;
}

ul.toggle > li {
  list-style: none;
}

ul {
  padding-inline-start: 1.7em;
}

ul > li {
  padding-left: 0.1em;
}

ol {
  padding-inline-start: 1.6em;
}

ol > li {
  padding-left: 0.2em;
}

.mono ol {
  padding-inline-start: 2em;
}

.mono ol > li {
  text-indent: -0.4em;
}

.toggle {
  padding-inline-start: 0em;
  list-style-type: none;
}

/* Indent toggle children */
.toggle > li > details {
  padding-left: 1.7em;
}

.toggle > li > details > summary {
  margin-left: -1.1em;
}

.selected-value {
  display: inline-block;
  padding: 0 0.5em;
  background: rgba(206, 205, 202, 0.5);
  border-radius: 3px;
  margin-right: 0.5em;
  margin-top: 0.3em;
  margin-bottom: 0.3em;
  white-space: nowrap;
}

.collection-title {
  display: inline-block;
  margin-right: 1em;
}

.page-description {
  margin-bottom: 2em;
}

.simple-table {
  margin-top: 1em;
  font-size: 0.875rem;
  empty-cells: show;
}
.simple-table td {
  height: 29px;
  min-width: 120px;
}

.simple-table th {
  height: 29px;
  min-width: 120px;
}

.simple-table-header-color {
  background: rgb(247, 246, 243);
  color: black;
}
.simple-table-header {
  font-weight: 500;
}

time {
  opacity: 0.5;
}

.icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  max-width: 1.2em;
  max-height: 1.2em;
  text-decoration: none;
  vertical-align: text-bottom;
  margin-right: 0.5em;
}

img.icon {
  border-radius: 3px;
}

.callout img.notion-static-icon {
  width: 1em;
  height: 1em;
}

.callout p {
  margin: 0;
}

.callout h1,
.callout h2,
.callout h3 {
  margin: 0 0 0.6rem;
}

.user-icon {
  width: 1.5em;
  height: 1.5em;
  border-radius: 100%;
  margin-right: 0.5rem;
}

.user-icon-inner {
  font-size: 0.8em;
}

.text-icon {
  border: 1px solid #000;
  text-align: center;
}

.page-cover-image {
  display: block;
  object-fit: cover;
  width: 100%;
  max-height: 30vh;
}

.page-header-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.page-header-icon-with-cover {
  margin-top: -0.72em;
  margin-left: 0.07em;
}

.page-header-icon img {
  border-radius: 3px;
}

.link-to-page {
  margin: 1em 0;
  padding: 0;
  border: none;
  font-weight: 500;
}

p > .user {
  opacity: 0.5;
}

td > .user,
td > time {
  white-space: nowrap;
}

input[type="checkbox"] {
  transform: scale(1.5);
  margin-right: 0.6em;
  vertical-align: middle;
}

p {
  margin-top: 0.5em;
  margin-bottom: 0.5em;
}

.image {
  border: none;
  margin: 1.5em 0;
  padding: 0;
  border-radius: 0;
  text-align: center;
}

.code,
code {
  background: rgba(135, 131, 120, 0.15);
  border-radius: 3px;
  padding: 0.2em 0.4em;
  border-radius: 3px;
  font-size: 85%;
  tab-size: 2;
}

code {
  color: #eb5757;
}

.code {
  padding: 1.5em 1em;
}

.code-wrap {
  white-space: pre-wrap;
  word-break: break-all;
}

.code > code {
  background: none;
  padding: 0;
  font-size: 100%;
  color: inherit;
}

blockquote {
  font-size: 1em;
  margin: 1em 0;
  padding-left: 1em;
  border-left: 3px solid rgb(55, 53, 47);
}

blockquote.quote-large {
  font-size: 1.25em;
}

.bookmark {
  text-decoration: none;
  max-height: 8em;
  padding: 0;
  display: flex;
  width: 100%;
  align-items: stretch;
}

.bookmark-title {
  font-size: 0.85em;
  overflow: hidden;
  text-overflow: ellipsis;
  height: 1.75em;
  white-space: nowrap;
}

.bookmark-text {
  display: flex;
  flex-direction: column;
}

.bookmark-info {
  flex: 4 1 180px;
  padding: 12px 14px 14px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.bookmark-image {
  width: 33%;
  flex: 1 1 180px;
  display: block;
  position: relative;
  object-fit: cover;
  border-radius: 1px;
}

.bookmark-description {
  color: rgba(55, 53, 47, 0.6);
  font-size: 0.75em;
  overflow: hidden;
  max-height: 4.5em;
  word-break: break-word;
}

.bookmark-href {
  font-size: 0.75em;
  margin-top: 0.25em;
}

.sans { font-family: ui-sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI Variable Display", "Segoe UI", Helvetica, "Apple Color Emoji", Arial, sans-serif, "Segoe UI Emoji", "Segoe UI Symbol"; }
.code { font-family: "SFMono-Regular", Menlo, Consolas, "PT Mono", "Liberation Mono", Courier, monospace; }
.serif { font-family: Lyon-Text, Georgia, ui-serif, serif; }
.mono { font-family: iawriter-mono, Nitti, Menlo, Courier, monospace; }
.pdf .sans { font-family: Inter, ui-sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI Variable Display", "Segoe UI", Helvetica, "Apple Color Emoji", Arial, sans-serif, "Segoe UI Emoji", "Segoe UI Symbol", 'Twemoji', 'Noto Color Emoji', 'Noto Sans CJK JP'; }
.pdf:lang(zh-CN) .sans { font-family: Inter, ui-sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI Variable Display", "Segoe UI", Helvetica, "Apple Color Emoji", Arial, sans-serif, "Segoe UI Emoji", "Segoe UI Symbol", 'Twemoji', 'Noto Color Emoji', 'Noto Sans CJK SC'; }
.pdf:lang(zh-TW) .sans { font-family: Inter, ui-sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI Variable Display", "Segoe UI", Helvetica, "Apple Color Emoji", Arial, sans-serif, "Segoe UI Emoji", "Segoe UI Symbol", 'Twemoji', 'Noto Color Emoji', 'Noto Sans CJK TC'; }
.pdf:lang(ko-KR) .sans { font-family: Inter, ui-sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI Variable Display", "Segoe UI", Helvetica, "Apple Color Emoji", Arial, sans-serif, "Segoe UI Emoji", "Segoe UI Symbol", 'Twemoji', 'Noto Color Emoji', 'Noto Sans CJK KR'; }
.pdf .code { font-family: Source Code Pro, "SFMono-Regular", Menlo, Consolas, "PT Mono", "Liberation Mono", Courier, monospace, 'Twemoji', 'Noto Color Emoji', 'Noto Sans Mono CJK JP'; }
.pdf:lang(zh-CN) .code { font-family: Source Code Pro, "SFMono-Regular", Menlo, Consolas, "PT Mono", "Liberation Mono", Courier, monospace, 'Twemoji', 'Noto Color Emoji', 'Noto Sans Mono CJK SC'; }
.pdf:lang(zh-TW) .code { font-family: Source Code Pro, "SFMono-Regular", Menlo, Consolas, "PT Mono", "Liberation Mono", Courier, monospace, 'Twemoji', 'Noto Color Emoji', 'Noto Sans Mono CJK TC'; }
.pdf:lang(ko-KR) .code { font-family: Source Code Pro, "SFMono-Regular", Menlo, Consolas, "PT Mono", "Liberation Mono", Courier, monospace, 'Twemoji', 'Noto Color Emoji', 'Noto Sans Mono CJK KR'; }
.pdf .serif { font-family: PT Serif, Lyon-Text, Georgia, ui-serif, serif, 'Twemoji', 'Noto Color Emoji', 'Noto Serif CJK JP'; }
.pdf:lang(zh-CN) .serif { font-family: PT Serif, Lyon-Text, Georgia, ui-serif, serif, 'Twemoji', 'Noto Color Emoji', 'Noto Serif CJK SC'; }
.pdf:lang(zh-TW) .serif { font-family: PT Serif, Lyon-Text, Georgia, ui-serif, serif, 'Twemoji', 'Noto Color Emoji', 'Noto Serif CJK TC'; }
.pdf:lang(ko-KR) .serif { font-family: PT Serif, Lyon-Text, Georgia, ui-serif, serif, 'Twemoji', 'Noto Color Emoji', 'Noto Serif CJK KR'; }
.pdf .mono { font-family: PT Mono, iawriter-mono, Nitti, Menlo, Courier, monospace, 'Twemoji', 'Noto Color Emoji', 'Noto Sans Mono CJK JP'; }
.pdf:lang(zh-CN) .mono { font-family: PT Mono, iawriter-mono, Nitti, Menlo, Courier, monospace, 'Twemoji', 'Noto Color Emoji', 'Noto Sans Mono CJK SC'; }
.pdf:lang(zh-TW) .mono { font-family: PT Mono, iawriter-mono, Nitti, Menlo, Courier, monospace, 'Twemoji', 'Noto Color Emoji', 'Noto Sans Mono CJK TC'; }
.pdf:lang(ko-KR) .mono { font-family: PT Mono, iawriter-mono, Nitti, Menlo, Courier, monospace, 'Twemoji', 'Noto Color Emoji', 'Noto Sans Mono CJK KR'; }
.highlight-default {
  color: rgba(44, 44, 43, 1);
}
.highlight-gray {
  color: rgba(134, 131, 126, 1);
  fill: rgba(134, 131, 126, 1);
}
.highlight-brown {
  color: rgba(159, 118, 90, 1);
  fill: rgba(159, 118, 90, 1);
}
.highlight-orange {
  color: rgba(210, 123, 45, 1);
  fill: rgba(210, 123, 45, 1);
}
.highlight-yellow {
  color: rgba(203, 148, 52, 1);
  fill: rgba(203, 148, 52, 1);
}
.highlight-teal {
  color: rgba(80, 148, 110, 1);
  fill: rgba(80, 148, 110, 1);
}
.highlight-blue {
  color: rgba(56, 125, 201, 1);
  fill: rgba(56, 125, 201, 1);
}
.highlight-purple {
  color: rgba(154, 107, 180, 1);
  fill: rgba(154, 107, 180, 1);
}
.highlight-pink {
  color: rgba(193, 76, 138, 1);
  fill: rgba(193, 76, 138, 1);
}
.highlight-red {
  color: rgba(207, 81, 72, 1);
  fill: rgba(207, 81, 72, 1);
}
.highlight-default_background {
  color: rgba(44, 44, 43, 1);
}
.highlight-gray_background {
  background: rgba(42, 28, 0, 0.07);
}
.highlight-brown_background {
  background: rgba(139, 46, 0, 0.086);
}
.highlight-orange_background {
  background: rgba(224, 101, 1, 0.129);
}
.highlight-yellow_background {
  background: rgba(211, 168, 0, 0.137);
}
.highlight-teal_background {
  background: rgba(0, 100, 45, 0.09);
}
.highlight-blue_background {
  background: rgba(0, 124, 215, 0.094);
}
.highlight-purple_background {
  background: rgba(102, 0, 178, 0.078);
}
.highlight-pink_background {
  background: rgba(197, 0, 93, 0.086);
}
.highlight-red_background {
  background: rgba(223, 22, 0, 0.094);
}
.block-color-default {
  color: inherit;
  fill: inherit;
}
.block-color-gray {
  color: rgba(134, 131, 126, 1);
  fill: rgba(134, 131, 126, 1);
}
.block-color-brown {
  color: rgba(159, 118, 90, 1);
  fill: rgba(159, 118, 90, 1);
}
.block-color-orange {
  color: rgba(210, 123, 45, 1);
  fill: rgba(210, 123, 45, 1);
}
.block-color-yellow {
  color: rgba(203, 148, 52, 1);
  fill: rgba(203, 148, 52, 1);
}
.block-color-teal {
  color: rgba(80, 148, 110, 1);
  fill: rgba(80, 148, 110, 1);
}
.block-color-blue {
  color: rgba(56, 125, 201, 1);
  fill: rgba(56, 125, 201, 1);
}
.block-color-purple {
  color: rgba(154, 107, 180, 1);
  fill: rgba(154, 107, 180, 1);
}
.block-color-pink {
  color: rgba(193, 76, 138, 1);
  fill: rgba(193, 76, 138, 1);
}
.block-color-red {
  color: rgba(207, 81, 72, 1);
  fill: rgba(207, 81, 72, 1);
}
.block-color-default_background {
  color: inherit;
  fill: inherit;
}
.block-color-gray_background {
  background: rgba(240, 239, 237, 1);
}
.block-color-brown_background {
  background: rgba(245, 237, 233, 1);
}
.block-color-orange_background {
  background: rgba(251, 235, 222, 1);
}
.block-color-yellow_background {
  background: rgba(249, 243, 220, 1);
}
.block-color-teal_background {
  background: rgba(232, 241, 236, 1);
}
.block-color-blue_background {
  background: rgba(229, 242, 252, 1);
}
.block-color-purple_background {
  background: rgba(243, 235, 249, 1);
}
.block-color-pink_background {
  background: rgba(250, 233, 241, 1);
}
.block-color-red_background {
  background: rgba(252, 233, 231, 1);
}
.select-value-color-default { background-color: rgba(42, 28, 0, 0.07); }
.select-value-color-gray { background-color: rgba(28, 19, 1, 0.11); }
.select-value-color-brown { background-color: rgba(127, 51, 0, 0.156); }
.select-value-color-orange { background-color: rgba(196, 88, 0, 0.203); }
.select-value-color-yellow { background-color: rgba(209, 156, 0, 0.282); }
.select-value-color-green { background-color: rgba(0, 96, 38, 0.156); }
.select-value-color-blue { background-color: rgba(0, 118, 217, 0.203); }
.select-value-color-purple { background-color: rgba(92, 0, 163, 0.141); }
.select-value-color-pink { background-color: rgba(183, 0, 78, 0.152); }
.select-value-color-red { background-color: rgba(206, 24, 0, 0.164); }

.checkbox {
  display: inline-flex;
  vertical-align: text-bottom;
  width: 16;
  height: 16;
  background-size: 16px;
  margin-left: 2px;
  margin-right: 5px;
}

.checkbox-on {
  background-image: url("data:image/svg+xml;charset=UTF-8,%3Csvg%20width%3D%2216%22%20height%3D%2216%22%20viewBox%3D%220%200%2016%2016%22%20fill%3D%22none%22%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%3E%0A%3Crect%20width%3D%2216%22%20height%3D%2216%22%20fill%3D%22%2358A9D7%22%2F%3E%0A%3Cpath%20d%3D%22M6.71429%2012.2852L14%204.9995L12.7143%203.71436L6.71429%209.71378L3.28571%206.2831L2%207.57092L6.71429%2012.2852Z%22%20fill%3D%22white%22%2F%3E%0A%3C%2Fsvg%3E");
}

.checkbox-off {
  background-image: url("data:image/svg+xml;charset=UTF-8,%3Csvg%20width%3D%2216%22%20height%3D%2216%22%20viewBox%3D%220%200%2016%2016%22%20fill%3D%22none%22%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%3E%0A%3Crect%20x%3D%220.75%22%20y%3D%220.75%22%20width%3D%2214.5%22%20height%3D%2214.5%22%20fill%3D%22white%22%20stroke%3D%22%2336352F%22%20stroke-width%3D%221.5%22%2F%3E%0A%3C%2Fsvg%3E");
}
  
</style></head><body><article id="1e8b6cb8-7440-8046-991f-dd435929932a" class="page sans"><header><div class="page-header-icon undefined"><img class="icon" src="Canny_Cat.png"/></div><h1 class="page-title">Privacy policy</h1><p class="page-description"></p></header><div class="page-body"><p id="1e8b6cb8-7440-8093-bbcc-c9ea0b85d3ef" class="">This privacy policy is here to let you know what we are going to use. Unlike other companies, you know who you are, we do care for your privacy and want to make sure you trust us when using Caroflags. </p><p id="29ab6cb8-7440-8029-a691-d06700ffad3c" class="">
</p><h1 id="29ab6cb8-7440-804e-920d-d5b662b681f5" class="">Definitions</h1><p id="29ab6cb8-7440-8048-abb9-cdcc7d16b94b" class="">For the sake of this being short, here are some basic things you need to know while reading this policy.</p><p id="29ab6cb8-7440-8081-bd5d-e6d8b16b0976" class="">
</p><ul id="29ab6cb8-7440-80fa-97db-f4e47d1b40cf" class="bulleted-list"><li style="list-style-type:disc">What an account is</li></ul><ul id="29ab6cb8-7440-80ab-83ef-d89e5561ee46" class="bulleted-list"><li style="list-style-type:disc">Where we are based (South Carolina)</li></ul><ul id="29ab6cb8-7440-8016-a58b-d9b4cae48c0f" class="bulleted-list"><li style="list-style-type:disc">Company (Caroflags <em>duh</em>)</li></ul><ul id="29ab6cb8-7440-80ac-a4c5-f1398ca2827c" class="bulleted-list"><li style="list-style-type:disc">Third-Parties (Firebase, Flutter)</li></ul><ul id="29ab6cb8-7440-8037-9ce7-eb16208a38da" class="bulleted-list"><li style="list-style-type:disc">What a tomato is</li></ul><ul id="29ab6cb8-7440-8077-8b96-d4fd3d3a0b3f" class="bulleted-list"><li style="list-style-type:disc">how to make crab stew</li></ul><ul id="29ab6cb8-7440-80d3-8b13-d2c5514658ef" class="bulleted-list"><li style="list-style-type:disc">What you are</li></ul><p id="29ab6cb8-7440-8017-bb92-fc1e9c3d2454" class="">
</p><h1 id="29ab6cb8-7440-807b-862c-e1ba47b56513" class="">What we collect</h1><p id="29ab6cb8-7440-809e-8f15-e583726af1e3" class="">
</p><p id="29ab6cb8-7440-80d6-848e-ee410869eec7" class="">When you use caroflags, you give us:</p><p id="29ab6cb8-7440-8009-8476-e49e9138cc57" class="">
</p><ul id="29ab6cb8-7440-8032-b3cc-c1ad113da81a" class="bulleted-list"><li style="list-style-type:disc">Your Email address</li></ul><ul id="29ab6cb8-7440-800f-8c93-c783f2491619" class="bulleted-list"><li style="list-style-type:disc">Your First name and or last name (This really depends if you put your real name in the username section during signup)</li></ul><div><ul id="29ab6cb8-7440-80f5-8ce9-ed60460e5576" class="bulleted-list"><li style="list-style-type:disc">Your GPS location</li></ul><ul id="29ab6cb8-7440-806f-b02f-f5a340f2f237" class="bulleted-list"><li style="list-style-type:disc">Your mobile device specs (Ram, Processor, Storage, Operating System)</li></ul></div><p id="29ab6cb8-7440-808c-abf4-df5671c706a4" class="">
</p><p id="29ab6cb8-7440-80fe-8e45-e970595cc4b2" class="">
</p><h1 id="29ab6cb8-7440-8039-be45-e2146d310245" class="">What will you do with this data?</h1><p id="29ab6cb8-7440-804c-b525-cfab013e35f1" class="">I am glad you asked myself!</p><p id="29ab6cb8-7440-8088-b2a0-d46b74c9f969" class="">
</p><p id="29ab6cb8-7440-804f-8608-c424e8fd8040" class="">With your email address, that is used to sign you in/up to Caroflags. If there is ever an issue and we need to reach-out to you, we will do it through your email or through the app if that ever becomes an option. We will use it to reset your password if you ever need that changed.</p><p id="29ab6cb8-7440-808c-93c7-ff516202d7ea" class="">
</p><p id="29ab6cb8-7440-8099-8e9f-d43ed200a1d4" class="">Your First name or last name will only be saved if you enter that content into the username box on the sign-up page.</p><p id="29ab6cb8-7440-80f0-972e-ea8196af902e" class="">
</p><p id="29ab6cb8-7440-80e3-b26d-cbc6f15b34d7" class="">Your GPS will never be saved on our servers. That is very personal data. Regardless if you trust  us, that data will always be saved on your device.</p><p id="29ab6cb8-7440-80e1-b1a6-fd5ec6f4dbaf" class="">
</p><p id="29ab6cb8-7440-8033-99b4-cdfb7fad7159" class="">The specifications on your device will be used for debugging caroflags and making it better for you, and the other users.</p><p id="29ab6cb8-7440-80b9-a45f-e19d35634f68" class="">
</p><p id="29ab6cb8-7440-805d-ae51-e2654e183265" class="">We will never sell your data.</p><p id="29ab6cb8-7440-8031-84d5-ea0436377409" class="">
</p><h1 id="29ab6cb8-7440-80ee-8a1f-d05f552715ae" class="">I do not trust you, how can i delete my data?</h1><p id="29ab6cb8-7440-800b-a5b0-d3df92ac72f1" class="">
</p><p id="29ab6cb8-7440-8062-a47a-cebd94751b62" class="">You can contact us and we will be happy to remove your data! (: Just so you know, You will not be able to use caroflags any longer unless you make it again with the same email. If you do decide to do so, we will miss you very much. Thanks for using caroflags and we hope to see you soon.</p><p id="29ab6cb8-7440-8001-ad3f-c7de1a8da363" class="">
</p><h1 id="29ab6cb8-7440-8054-a88b-deed17821034" class="">Third parties</h1><p id="29ab6cb8-7440-805f-907c-ed0a8979632e" class=""><br/>We use Firebase and Flutter to help run the app. Firebase may process some device identifiers and push notification tokens to deliver notifications. We <strong>do not share or sell this data to advertisers</strong>, and it is used only for app functionality and analytics.<br/><br/></p><h1 id="29ab6cb8-7440-8068-99bd-f18503f36043" class="">Any questions?</h1><p id="29ab6cb8-7440-809b-85b4-e6893cf588ef" class="">
</p><p id="29ab6cb8-7440-8070-ade5-fafbde8e35a1" class="">You are free to email us at <a href="mailto:privacyconcerns@caroflags.xyz">privacyconcerns@caroflags.xyz</a> and we will be happy to contact you.</p><p id="29ab6cb8-7440-80cf-82b5-d302bd2dc7dd" class="">
</p><p id="29ab6cb8-7440-802c-b680-f11480e2fb52" class="">
</p><p id="29ab6cb8-7440-80fd-b964-f9588fb5d9ef" class="">
</p></div></article><span class="sans" style="font-size:14px;padding-top:2em"></span></body></html>
''';

    return Scaffold(
      appBar: AppBar(
        title: Text("Privacy Policy"),
      ),
      body: SingleChildScrollView(
        child: Html(
          data: htmlContent,
        ),
      ),
    );
  }
}