import{_ as s,c as a,o as i,a2 as e}from"./chunks/framework.BCsSUL46.js";const E=JSON.parse('{"title":"","description":"","frontmatter":{},"headers":[],"relativePath":"libs/Signal/README.md","filePath":"libs/Signal/README.md"}'),t={name:"libs/Signal/README.md"},l=e(`<h3 id="signal" tabindex="-1">Signal <a class="header-anchor" href="#signal" aria-label="Permalink to &quot;Signal&quot;">​</a></h3><p>A pure Luau signal implementation, based on LemonSignal &amp; robloxs signal-lua. With thread reuse as an option that can be used with the constructors.</p><h4 id="example" tabindex="-1">example <a class="header-anchor" href="#example" aria-label="Permalink to &quot;example&quot;">​</a></h4><div class="language-luau vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">luau</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">local</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> signal </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> require</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;@kalrnlo/Signal&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">local</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> regular_signal, fire </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> signal.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">create</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">regular_signal:</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">subscribe</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">function</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(...)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    print</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;signal was fired! wahoo!!&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">...</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">fire</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;foo&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;bar&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">local</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> value_signal, set </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> signal.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">value</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">10</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">value_signal:</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">once</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">function</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(val)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    print</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;i only print the next time this updates!&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, val)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">set</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">20</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">set</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">30</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><h3 id="api" tabindex="-1">api <a class="header-anchor" href="#api" aria-label="Permalink to &quot;api&quot;">​</a></h3><h4 id="constructors" tabindex="-1">constructors <a class="header-anchor" href="#constructors" aria-label="Permalink to &quot;constructors&quot;">​</a></h4><div class="language-lua vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">lua</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">create</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(reuse_threads, pre_allocate_threads)</span></span></code></pre></div><ul><li>reuse_threads: boolean indicating whether or not the signal created should partake in thread reuse</li><li>pre_allocate_threads: a number of threads to preallocate, by defualt 2</li></ul><div class="language-lua vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">lua</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">value</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&lt;value&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(value, reuse_threads, pre_allocate_threads)</span></span></code></pre></div><ul><li><code>note: value signals only fire their connections if the new value is different from the old value</code></li><li>value: the starting value for the value signal, value signals are diffrent in that they store a singular value, and the fire function is replaced with a set function to set the value</li><li>reuse_threads: boolean indicating whether or not the signal created should partake in thread reuse</li><li>pre_allocate_threads: a number of threads to preallocate, by defualt 2</li></ul><h4 id="methods" tabindex="-1">methods <a class="header-anchor" href="#methods" aria-label="Permalink to &quot;methods&quot;">​</a></h4><div class="language-lua vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">lua</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">signal</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">subscribe</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(callback)</span></span></code></pre></div><ul><li>callback: a function that runs whenever the signal fires, with paramters that are the signals values</li></ul><div class="language-lua vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">lua</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">signal</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">wait</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span></code></pre></div><p>Yields the current thread, and resumes the current thread with the values when from the signal is fired next</p><div class="language-lua vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">lua</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">signal</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">once</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(callback)</span></span></code></pre></div><p>Same as <code>signal:subscribe()</code>, except for the fact it disconnects the callback after the next time the signal is fired</p><h4 id="properties" tabindex="-1">properties <a class="header-anchor" href="#properties" aria-label="Permalink to &quot;properties&quot;">​</a></h4><div class="language-lua vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">lua</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">signal.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">connections</span></span></code></pre></div><p>An array of all of the connections the signal has, including threads for that called <code>signal:Wait()</code> and are waiting to be resumed the next time the signal is fired</p><div class="language-lua vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">lua</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">signal.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">thread_pool</span></span></code></pre></div><p><code>note: this is exclusive to reuse signals only</code></p><p>An array holding all of the threads that are currently unused that are pre-allocated for the reuse signal</p><div class="language-lua vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">lua</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">signal.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">value</span></span></code></pre></div><p><code>note: this is exclusive to value signals only</code></p><p>The current value stored by the value signal</p>`,26),n=[l];function h(p,k,r,d,o,c){return i(),a("div",null,n)}const u=s(t,[["render",h]]);export{E as __pageData,u as default};