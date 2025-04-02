---
layout: default
title: Welcome to Warpack Masters
---

<div class="hero">
  <h1>Welcome to Warpack Masters</h1>
  <p class="hero-text">Master the art of strategic combat in this Backpack management FOCG</p>
  <div class="buttons">
    <a href="{{ 'tutorials/getting-started' | relative_url }}" class="button primary">Get Started</a>
    <a href="{{ 'mechanics/combat' | relative_url }}" class="button secondary">Game Mechanics</a>
  </div>
</div>

<div class="features">
  <div class="feature">
    <h2>Strategic Combat</h2>
    <p>Master a deep combat system with status effects, cooldowns, and strategic item placement.</p>
  </div>
  
  <div class="feature">
    <h2>Item Customization</h2>
    <p>Collect and position items in your inventory to create powerful synergies and builds.</p>
  </div>
</div>

<div class="content-section">
  <h2>Latest Tutorials</h2>
  <div class="card-grid">
    {% for tutorial in site.tutorials limit:3 %}
    <a href="{{ tutorial.url | relative_url }}" class="card">
      <h3>{{ tutorial.title }}</h3>
      <p>{{ tutorial.description | truncate: 100 }}</p>
      <span class="read-more">Read More →</span>
    </a>
    {% endfor %}
  </div>
</div>

<div class="content-section">
  <h2>Game Mechanics</h2>
  <div class="card-grid">
    {% for mechanic in site.mechanics limit:3 %}
    <a href="{{ mechanic.url | relative_url }}" class="card">
      <h3>{{ mechanic.title }}</h3>
      <p>{{ mechanic.description | truncate: 100 }}</p>
      <span class="read-more">Read More →</span>
    </a>
    {% endfor %}
  </div>
</div>
