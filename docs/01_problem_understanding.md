# Problem understanding

Instagram’s data platform needs to serve interactive social features and reliable creator and business reporting. The current exports have no documented schema, stored counters can drift from underlying relationships, and the workload is expected to grow substantially. Phase 1 establishes the product need and performance class; later phases measure the supplied SQL workload and improve it without changing results.

| Problem | Business need and affected stakeholder | Class |
|---|---|---|
| P1 · Home feed and profile grid are slow | End users need recent posts from followed accounts and a fast profile view; the feed team owns delivery. | Customer-facing / real-time |
| P2 · Viral post pages are slow | End users need comments and reply counts, liker lists, and like state to respond quickly; post-page team is affected. | Customer-facing / real-time |
| P3 · Explore and search are slow | Users and creators need quick hashtag, place, and account discovery; explore and search teams are affected. | Customer-facing / real-time |
| P4 · Suggestions and requests lag | Users need useful account suggestions and private-account owners need prompt request management; social graph team is affected. | Customer-facing / real-time |
| P5 · Creator insights are missing or slow | Creators and business accounts need engagement, audience, follow-back, and Reels performance metrics to guide content decisions. | Reporting / analytics |
| P6 · Comments without replies returns nothing | Creators need to find unanswered comments so they can engage; creator tools and affected creators are stakeholders. | Customer-facing / real-time |
| P7 · Profile counters are inaccurate and recounts slow | Users and creators expect trustworthy profile counts; data quality team needs accurate and maintainable aggregates. | Reporting / analytics |
| P8 · Stories and moderation are slow | Users need usable highlights and insights, while trust and safety staff need timely moderation and cleanup tools. | Customer-facing / real-time for highlights/moderation; reporting / analytics for insights |
| P9 · Analytics time out as data grows | Growth analytics and the business need reliable content reports at an expected 20× scale. | Reporting / analytics |

## Assumptions

- “Real-time” means an interactive request on a user-facing screen; the brief does not provide numeric latency targets, which will be set from measured baseline results.
- The supplied 9 CSV files are the authoritative scope for schema reconstruction. The 30 supplied workload queries define compatibility requirements and must retain their results.
- Stored counts are snapshots maintained by application or batch logic. They may be stale and therefore are not required to equal relationship-table counts at all times.
- Story expiry is modeled as exactly 24 hours after creation because that is the stated product rule and is true for every seed row.
- Private-account pending follows are requests; only accepted follows represent an active relationship.
