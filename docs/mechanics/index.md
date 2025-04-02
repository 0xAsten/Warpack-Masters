---
layout: collection
title: Game Mechanics
collection: mechanics
description: Detailed explanations of Warpack Masters game mechanics
---

{% for mechanic in site.mechanics %}
  {% if mechanic.url != page.url %}
  <div class="mechanic-card">
    <h2><a href="{{ mechanic.url | relative_url }}">{{ mechanic.title }}</a></h2>
    <p>{{ mechanic.description }}</p>
  </div>
  {% endif %}
{% endfor %} 