---
title: "Posts by Tag"
permalink: /tags/
layout: archive
author_profile: true
---

{% assign all_docs = site.experiences | concat: site.knowledge %}
{% assign tags_list = "" | split: "," %}
{% for doc in all_docs %}
  {% if doc.tags.size > 0 %}
    {% for tag in doc.tags %}
      {% if tag and tag != "" %}
        {% assign tags_list = tags_list | push: tag %}
      {% endif %}
    {% endfor %}
  {% endif %}
{% endfor %}
{% assign tags_unique = tags_list | compact | uniq | sort %}

<p class="taxonomy__index">
{%- for tag in tags_unique -%}
  {% assign count = 0 %}
  {%- for doc in all_docs -%}
    {%- if doc.tags contains tag -%}
      {% assign count = count | plus: 1 %}
    {%- endif -%}
  {%- endfor -%}
  <a href="#{{ tag | slugify }}"><strong>{{ tag }}</strong> <span class="taxonomy__count">{{ count }}</span></a>
{%- endfor -%}
</p>

{% for tag in tags_unique %}
<h2 id="{{ tag | slugify }}" class="archive__subtitle">{{ tag }}</h2>
{% for post in all_docs %}
  {% if post.tags contains tag %}
    {% include archive-single.html %}
  {% endif %}
{% endfor %}
{% endfor %}
