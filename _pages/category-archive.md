---
title: "Posts by Category"
layout: archive
permalink: /categories/
author_profile: true
---

{% assign all_docs = site.experiences | concat: site.knowledge %}
{% assign categories_list = "" | split: "," %}
{% for doc in all_docs %}
  {% if doc.categories.size > 0 %}
    {% for cat in doc.categories %}
      {% if cat and cat != "" %}
        {% assign categories_list = categories_list | push: cat %}
      {% endif %}
    {% endfor %}
  {% endif %}
{% endfor %}
{% assign categories_unique = categories_list | compact | uniq | sort %}

<p class="taxonomy__index">
{%- for category in categories_unique -%}
  {% assign count = 0 %}
  {%- for doc in all_docs -%}
    {%- if doc.categories contains category -%}
      {% assign count = count | plus: 1 %}
    {%- endif -%}
  {%- endfor -%}
  <a href="#{{ category | slugify }}"><strong>{{ category }}</strong> <span class="taxonomy__count">{{ count }}</span></a>
{%- endfor -%}
</p>

{% for category in categories_unique %}
<h2 id="{{ category | slugify }}" class="archive__subtitle">{{ category }}</h2>
{% for post in all_docs %}
  {% if post.categories contains category %}
    {% include archive-single.html %}
  {% endif %}
{% endfor %}
{% endfor %}
