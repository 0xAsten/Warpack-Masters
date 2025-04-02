---
layout: collection
title: Tutorials
collection: tutorials
description: Learn how to play Warpack Masters with our comprehensive tutorials
---

{% for tutorial in site.tutorials %}
  {% if tutorial.url != page.url %}
  <div class="tutorial-card">
    <h2><a href="{{ tutorial.url | relative_url }}">{{ tutorial.title }}</a></h2>
    <p>{{ tutorial.description }}</p>
  </div>
  {% endif %}
{% endfor %} 