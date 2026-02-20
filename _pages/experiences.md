---
title: "Experiences"
permalink: /experiences/
layout: archive
author_profile: true
---

{% assign posts = site.experiences | sort: 'date' | reverse %}
{% for post in posts %}
  {% include archive-single.html %}
{% endfor %}