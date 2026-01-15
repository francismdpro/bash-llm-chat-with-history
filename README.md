# OpenRouter Chat CLI

Un client CHATBOT écrit en bash pour l'API OpenRouter (avec des modèles gratuits avec 1000 requêtes par jour si vous avez 10$ sur votre compte OpenRouter). Ce script permet d'interagir avec différents modèles d'IA (GPT-4, Claude, Llama, Gemini, etc.) directement depuis votre terminal, avec gestion complète des conversations et historique.

## ✨ Fonctionnalités

- 💬 **Chat interactif** en ligne de commande
- 💾 **Sauvegarde et chargement** de conversations
- 🔄 **Changement de modèle** à la volée
- 📋 **Gestion d'historique** avec timestamps
- 🎯 **Support de multiples modèles** OpenRouter (gratuits et payants)
- 🔐 **Configuration persistante** de la clé API
- 🎨 **Interface claire** avec commandes intuitives

## 📋 Prérequis

- Bash 4.0 ou supérieur
- Python 3.6+
- curl
- Une clé API OpenRouter (gratuite sur [openrouter.ai](https://openrouter.ai))

## 🚀 Installation

```bash
# Télécharger le script
git pull https://raw.githubusercontent.com/francismdpro/bash-llm-chat-with-history

# Executer
bash chat.sh

ou

bash chat.sh -k <clé openrouter.ai>


