#!/bin/bash

# Configuration
CONFIG_DIR="$HOME/.config/openrouter-chat"
CONFIG_FILE="$CONFIG_DIR/config.json"
CONVERSATIONS_FILE="$CONFIG_DIR/conversations.json"
API_KEY=""
MODEL="allenai/molmo-2-8b:free"

# Créer le répertoire de configuration si nécessaire
mkdir -p "$CONFIG_DIR"

# Fonction pour lire une valeur JSON avec Python
get_json_value() {
    local file="$1"
    local key="$2"
    python3 -c "
import json
import sys
try:
    with open(sys.argv[1], 'r') as f:
        data = json.load(f)
        print(data.get(sys.argv[2], ''))
except:
    print('')
" "$file" "$key"
}

# Fonction pour écrire une valeur JSON avec Python
set_json_value() {
    local file="$1"
    local key="$2"
    local value="$3"
    python3 -c "
import json
import sys
try:
    with open(sys.argv[1], 'r') as f:
        data = json.load(f)
except:
    data = {}

data[sys.argv[2]] = sys.argv[3]

with open(sys.argv[1], 'w') as f:
    json.dump(data, f, indent=2)
" "$file" "$key" "$value"
}

# Charger la configuration existante si elle existe
if [[ -f "$CONFIG_FILE" ]]; then
    API_KEY=$(get_json_value "$CONFIG_FILE" "api_key")
    MODEL=$(get_json_value "$CONFIG_FILE" "model")
    if [[ -z "$MODEL" ]]; then
        MODEL="allenai/molmo-2-8b:free"
    fi
fi

# Fonction pour sauvegarder la configuration
save_config() {
    set_json_value "$CONFIG_FILE" "api_key" "$API_KEY"
    set_json_value "$CONFIG_FILE" "model" "$MODEL"
}

# Fonction pour afficher l'aide
show_help() {
    echo "Utilisation: $0 [options]"
    echo
    echo "Options:"
    echo "  -h, --help            Afficher cette aide"
    echo "  -k, --api-key KEY     Définir la clé API OpenRouter"
    echo "  -m, --model MODEL     Définir le modèle (par défaut: $MODEL)"
    echo "  -l, --list            Lister les conversations sauvegardées"
    echo "  -c, --continue ID     Continuer une conversation existante"
    echo "  -d, --delete ID       Supprimer une conversation"
    echo
    echo "Si aucun argument n'est fourni, démarre une nouvelle conversation interactive."
}

# Fonction pour afficher l'aide interactive
show_interactive_help() {
    echo
    echo "=== Commandes disponibles ==="
    echo "  help              Afficher cette aide"
    echo "  list              Lister et charger une conversation sauvegardée"
    echo "  save              Sauvegarder la conversation actuelle"
    echo "  clear             Effacer l'historique et recommencer"
    echo "  model [NOM]       Changer de modèle (affiche les modèles si pas d'argument)"
    echo "  quit, exit        Quitter le chat"
    echo "=============================="
    echo
}

# Fonction pour lister les conversations avec détails
list_conversations_detailed() {
    if [[ ! -f "$CONVERSATIONS_FILE" ]] || [[ $(wc -c < "$CONVERSATIONS_FILE") -eq 0 ]]; then
        echo "Aucune conversation sauvegardée."
        return 1
    fi

    echo
    echo "=== Conversations sauvegardées ==="
    python3 -c "
import json
import sys
from datetime import datetime

try:
    with open(sys.argv[1], 'r') as f:
        data = json.load(f)
    
    if not data:
        print('Aucune conversation sauvegardée.')
        sys.exit(1)
    
    for i, conv in enumerate(data):
        conv_id = conv.get('id', 'N/A')
        title = conv.get('title', 'Sans titre')
        model = conv.get('model', 'Modèle inconnu')
        timestamp = conv.get('timestamp', 0)
        msg_count = len(conv.get('messages', []))
        
        date_str = datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d %H:%M') if timestamp else 'Date inconnue'
        
        print(f'{i}. [{conv_id}] {title}')
        print(f'   Modèle: {model} | Messages: {msg_count} | Date: {date_str}')
        print()
except Exception as e:
    print(f'Erreur: {e}')
    sys.exit(1)
" "$CONVERSATIONS_FILE"
    
    return 0
}

# Fonction pour lister les conversations (format simple)
list_conversations() {
    if [[ ! -f "$CONVERSATIONS_FILE" ]] || [[ $(wc -c < "$CONVERSATIONS_FILE") -eq 0 ]]; then
        echo "Aucune conversation sauvegardée."
        return
    fi

    echo "Conversations sauvegardées:"
    python3 -c "
import json
import sys
with open(sys.argv[1], 'r') as f:
    data = json.load(f)
    for i, conv in enumerate(data):
        print(f\"{i}: {conv.get('title', 'Sans titre')} - {conv.get('model', 'Modèle inconnu')}\")
" "$CONVERSATIONS_FILE"
}

# Fonction pour charger une conversation par index
load_conversation_by_index() {
    local index="$1"
    python3 -c "
import json
import sys
try:
    with open(sys.argv[1], 'r') as f:
        data = json.load(f)
    
    index = int(sys.argv[2])
    if 0 <= index < len(data):
        print(json.dumps(data[index]))
    else:
        print('{}')
except:
    print('{}')
" "$CONVERSATIONS_FILE" "$index"
}

# Fonction pour charger une conversation
load_conversation() {
    local id="$1"
    python3 -c "
import json
import sys
try:
    with open(sys.argv[1], 'r') as f:
        data = json.load(f)
        for conv in data:
            if str(conv.get('id')) == sys.argv[2]:
                print(json.dumps(conv))
                break
except:
    print('{}')
" "$CONVERSATIONS_FILE" "$id"
}

# Fonction pour sauvegarder une conversation
save_conversation() {
    local id="$1"
    local title="$2"
    local model="$3"
    local messages="$4"
    local timestamp=$(date +%s)

    python3 -c "
import json
import sys

new_conv = {
    'id': sys.argv[1],
    'title': sys.argv[2],
    'model': sys.argv[3],
    'messages': json.loads(sys.argv[4]),
    'timestamp': int(sys.argv[5])
}

try:
    with open(sys.argv[6], 'r') as f:
        data = json.load(f)
except:
    data = []

# Supprimer l'ancienne conversation si elle existe
data = [conv for conv in data if str(conv.get('id')) != sys.argv[1]]

# Ajouter la nouvelle conversation
data.append(new_conv)

with open(sys.argv[6], 'w') as f:
    json.dump(data, f, indent=2)
" "$id" "$title" "$model" "$messages" "$timestamp" "$CONVERSATIONS_FILE"
}

# Fonction pour générer un ID unique
generate_id() {
    date +%s%N | md5sum | head -c 8
}

# Fonction pour envoyer une requête à l'API OpenRouter
send_to_openrouter() {
    local messages="$1"
    local model="${2:-openrouter/auto}"

    local response
    response=$(curl --ssl-no-revoke -s -X POST "https://openrouter.ai/api/v1/chat/completions" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"model\": \"$model\", \"messages\": $messages, \"stream\": false}")

    # Vérifier si la réponse est vide ou contient une erreur
    if [ -z "$response" ]; then
        echo "Erreur: réponse vide de l'API" >&2
        return 1
    fi

    echo "$response"
}

# Fonction pour afficher les modèles populaires
show_models() {
    echo
    echo "=== Modèles populaires OpenRouter ==="
    echo "Gratuits:"
    echo "  - allenai/molmo-2-8b:free"
    echo "  - google/gemini-flash-1.5:free"
    echo "  - meta-llama/llama-3.2-3b-instruct:free"
    echo "  - qwen/qwen-2-7b-instruct:free"
    echo
    echo "Payants (performants):"
    echo "  - anthropic/claude-3.5-sonnet"
    echo "  - openai/gpt-4-turbo"
    echo "  - google/gemini-pro-1.5"
    echo "  - meta-llama/llama-3.1-70b-instruct"
    echo
    echo "Auto-routing:"
    echo "  - openrouter/auto (sélection automatique)"
    echo "===================================="
    echo
}

# Fonction pour le chat interactif
interactive_chat() {
    local conversation_id="${1:-$(generate_id)}"
    local title="${2:-"Nouvelle conversation"}"
    local model="${3:-$MODEL}"

    # Charger la conversation existante si un ID est fourni
    local messages="[]"
    if [[ -n "$1" ]]; then
        local loaded_conversation
        loaded_conversation=$(load_conversation "$conversation_id")
        if [[ -n "$loaded_conversation" ]] && [[ "$loaded_conversation" != "{}" ]]; then
            messages=$(echo "$loaded_conversation" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(json.dumps(data.get('messages', [])))
")
            model=$(echo "$loaded_conversation" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('model', sys.argv[1]))
" "$MODEL")
            local current_title
            current_title=$(echo "$loaded_conversation" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('title', 'Sans titre'))
")
            echo "Reprenant la conversation: $current_title"
        fi
    fi

    echo "=== Chat OpenRouter (ID: $conversation_id) ==="
    echo "Modèle: $model"
    echo "Tapez 'help' pour voir les commandes disponibles."
    echo "=============================================="
    echo

    while true; do
        read -e -p "> " user_input

        case "$user_input" in
            quit|exit)
                echo "Au revoir!"
                break
                ;;
            help)
                show_interactive_help
                continue
                ;;
            list)
                if list_conversations_detailed; then
                    read -p "Entrez le numéro de la conversation à charger (ou Entrée pour annuler): " conv_index
                    if [[ -n "$conv_index" ]] && [[ "$conv_index" =~ ^[0-9]+$ ]]; then
                        local new_conversation
                        new_conversation=$(load_conversation_by_index "$conv_index")
                        if [[ -n "$new_conversation" ]] && [[ "$new_conversation" != "{}" ]]; then
                            conversation_id=$(echo "$new_conversation" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('id', ''))
")
                            messages=$(echo "$new_conversation" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(json.dumps(data.get('messages', [])))
")
                            model=$(echo "$new_conversation" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('model', sys.argv[1]))
" "$MODEL")
                            title=$(echo "$new_conversation" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('title', 'Sans titre'))
")
                            echo
                            echo "=== Conversation chargée: $title ==="
                            echo "ID: $conversation_id | Modèle: $model"
                            
                            # Afficher l'historique
                            local msg_count
                            msg_count=$(echo "$messages" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(len(data))
")
                            echo "Messages chargés: $msg_count"
                            echo "===================================="
                            echo
                        else
                            echo "Erreur: conversation invalide"
                        fi
                    fi
                fi
                continue
                ;;
            save)
                read -p "Titre de la conversation: " title
                if [[ -z "$title" ]]; then
                    title="Conversation du $(date '+%Y-%m-%d %H:%M')"
                fi
                save_conversation "$conversation_id" "$title" "$model" "$messages"
                echo "✓ Conversation sauvegardée avec l'ID: $conversation_id"
                continue
                ;;
            clear)
                read -p "Effacer l'historique et recommencer? (o/N): " confirm
                if [[ "$confirm" == "o" ]] || [[ "$confirm" == "O" ]]; then
                    messages="[]"
                    conversation_id=$(generate_id)
                    echo "✓ Historique effacé. Nouvelle conversation (ID: $conversation_id)"
                fi
                continue
                ;;
            model|model\ *)
                if [[ "$user_input" == "model" ]]; then
                    show_models
                    read -p "Entrez le nom du modèle (ou Entrée pour garder $model): " new_model
                    if [[ -n "$new_model" ]]; then
                        model="$new_model"
                        MODEL="$new_model"
                        save_config
                        echo "✓ Modèle changé: $model"
                    fi
                else
                    model="${user_input#model }"
                    MODEL="$model"
                    save_config
                    echo "✓ Modèle changé: $model"
                fi
                continue
                ;;
            "")
                continue
                ;;
            *)
                # Ajouter le message de l'utilisateur
                messages=$(python3 -c "
import json, sys
data = json.loads(sys.argv[1])
data.append({'role': 'user', 'content': sys.argv[2]})
print(json.dumps(data))
" "$messages" "$user_input")

                # Envoyer à l'API et obtenir la réponse
                echo -n "Assistant: "
                local response
                response=$(send_to_openrouter "$messages" "$model")
                
                # Vérifier si la réponse est vide
                if [ -z "$response" ]; then
                    echo "Erreur: réponse vide de l'API"
                    echo
                    # Retirer le dernier message utilisateur
                    messages=$(python3 -c "
import json, sys
data = json.loads(sys.argv[1])
if data:
    data.pop()
print(json.dumps(data))
" "$messages")
                    continue
                fi

                # Extraire la réponse de l'assistant en toute sécurité
                local assistant_message
                assistant_message=$(echo "$response" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    if 'choices' in data and len(data['choices']) > 0:
        print(data['choices'][0]['message']['content'])
    elif 'error' in data:
        print(f\"Erreur API: {data['error'].get('message', 'Erreur inconnue')}\")
    else:
        print('Erreur: format de réponse inattendu')
except Exception as e:
    print(f'Erreur lors du parsing: {e}')
")

                if [[ -z "$assistant_message" ]]; then
                    echo "Erreur: impossible d'extraire la réponse"
                    echo
                    # Retirer le dernier message utilisateur
                    messages=$(python3 -c "
import json, sys
data = json.loads(sys.argv[1])
if data:
    data.pop()
print(json.dumps(data))
" "$messages")
                    continue
                fi

                # Ajouter la réponse de l'assistant
                messages=$(python3 -c "
import json, sys
data = json.loads(sys.argv[1])
data.append({'role': 'assistant', 'content': sys.argv[2]})
print(json.dumps(data))
" "$messages" "$assistant_message")

                # Afficher la réponse
                echo "$assistant_message"
                echo
                ;;
        esac
    done
}

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -k|--api-key)
            API_KEY="$2"
            save_config
            shift 2
            ;;
        -m|--model)
            MODEL="$2"
            save_config
            shift 2
            ;;
        -l|--list)
            list_conversations
            exit 0
            ;;
        -c|--continue)
            if [[ -z "$2" ]]; then
                echo "Erreur: ID de conversation requis pour --continue"
                exit 1
            fi
            interactive_chat "$2"
            exit 0
            ;;
        -d|--delete)
            if [[ -z "$2" ]]; then
                echo "Erreur: ID de conversation requis pour --delete"
                exit 1
            fi
            python3 -c "
import json
import sys
try:
    with open(sys.argv[1], 'r') as f:
        data = json.load(f)
    data = [conv for conv in data if str(conv.get('id')) != sys.argv[2]]
    with open(sys.argv[1], 'w') as f:
        json.dump(data, f, indent=2)
    print(f'Conversation {sys.argv[2]} supprimée.')
except Exception as e:
    print(f'Erreur lors de la suppression: {e}')
" "$CONVERSATIONS_FILE" "$2"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Vérifier que la clé API est configurée
if [[ -z "$API_KEY" ]]; then
    read -p "Veuillez entrer votre clé API OpenRouter: " API_KEY
    save_config
fi

# Démarrer le chat interactif
interactive_chat
