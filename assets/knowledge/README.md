# Crop-disease knowledge base

The reference cards that ground CropSight's answers now live as Dart data in
`lib/core/rag/knowledge_base.dart` (guaranteed offline, no asset IO). This folder
is reserved for a future expansion where cards are authored as loose files and
loaded at build time. When you edit the cards, bump `KnowledgeBase.version` so the
on-device embeddings are rebuilt.
