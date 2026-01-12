#!/bin/sh
# GPT-2 Chat App for spruceOS
# D-pad keyboard input, context-managed conversation

. /mnt/SDCARD/spruce/scripts/helperFunctions.sh

APP_DIR="/mnt/SDCARD/App/MemeAI"
MODEL_BIN="$APP_DIR/gpt2-meme"
MODEL_FILE="$APP_DIR/models/gpt2-124M-q4_0.bin"
CHAT_HISTORY="$APP_DIR/chat_history.txt"
CONTEXT_FILE="$APP_DIR/context.txt"
MAX_CONTEXT_MESSAGES=6

# Keyboard layout - 6 rows for small screen
KB_ROW1="a b c d e f g"
KB_ROW2="h i j k l m n"
KB_ROW3="o p q r s t u"
KB_ROW4="v w x y z . ?"
KB_ROW5="1 2 3 4 5 6 7"
KB_ROW6="8 9 0 ! , ' -"

# Current position
KB_X=0
KB_Y=0
KB_ROWS=6
KB_COLS=7

# Input buffer
INPUT_TEXT=""

# Get character at position
get_char_at() {
    local x=$1
    local y=$2
    local row=""
    case $y in
        0) row="$KB_ROW1" ;;
        1) row="$KB_ROW2" ;;
        2) row="$KB_ROW3" ;;
        3) row="$KB_ROW4" ;;
        4) row="$KB_ROW5" ;;
        5) row="$KB_ROW6" ;;
    esac
    echo "$row" | cut -d' ' -f$((x + 1))
}

# Build keyboard display with cursor
build_keyboard_display() {
    local display_text=""
    local y=0
    while [ $y -lt $KB_ROWS ]; do
        local x=0
        local row=""
        case $y in
            0) row="$KB_ROW1" ;;
            1) row="$KB_ROW2" ;;
            2) row="$KB_ROW3" ;;
            3) row="$KB_ROW4" ;;
            4) row="$KB_ROW5" ;;
            5) row="$KB_ROW6" ;;
        esac

        # Build row with cursor highlight
        local row_display=""
        for char in $row; do
            if [ $x -eq $KB_X ] && [ $y -eq $KB_Y ]; then
                row_display="$row_display[$char]"
            else
                row_display="$row_display $char "
            fi
            x=$((x + 1))
        done
        display_text="$display_text$row_display
"
        y=$((y + 1))
    done
    echo "$display_text"
}

# Display the chat UI
display_chat_ui() {
    local kb_display=$(build_keyboard_display)
    local truncated_input=$(echo "$INPUT_TEXT" | tail -c 30)

    # Show: input text, keyboard, and controls hint
    local full_display="Input: ${truncated_input}_

$kb_display
A:sel Y:del X:spc START:send B:quit"

    display -t "$full_display" -s 18 -p 50 --timeout 0
}

# Display chat history and response
display_response() {
    local response="$1"
    # Truncate response for display
    local truncated=$(echo "$response" | head -c 400)
    display -t "AI: $truncated" -s 20 -p 100 --timeout 0
}

# Add message to context
add_to_context() {
    local role="$1"
    local message="$2"
    echo "$role: $message" >> "$CONTEXT_FILE"

    # Keep only last N messages
    if [ -f "$CONTEXT_FILE" ]; then
        tail -n $MAX_CONTEXT_MESSAGES "$CONTEXT_FILE" > "$CONTEXT_FILE.tmp"
        mv "$CONTEXT_FILE.tmp" "$CONTEXT_FILE"
    fi
}

# Build prompt from context
build_prompt() {
    local user_input="$1"
    local prompt=""

    if [ -f "$CONTEXT_FILE" ]; then
        prompt=$(cat "$CONTEXT_FILE")
        prompt="$prompt
"
    fi

    prompt="${prompt}User: $user_input
AI:"
    echo "$prompt"
}

# Generate response using GPT-2
generate_response() {
    local user_input="$1"
    local prompt=$(build_prompt "$user_input")

    # GPT-2 inference
    local response=$("$MODEL_BIN" -m "$MODEL_FILE" -p "$prompt" -n 60 -t 2 --temp 0.8 --top_k 40 --top_p 0.9 2>/dev/null)
    # Extract just the AI response (after the prompt)
    echo "$response" | sed "s/.*AI://" | head -c 300
}

# Main keyboard input loop
keyboard_input_loop() {
    INPUT_TEXT=""
    KB_X=0
    KB_Y=0

    while true; do
        display_chat_ui

        # Wait for button press
        BUTTON=$(get_button_press 300)

        case "$BUTTON" in
            "UP")
                KB_Y=$(( (KB_Y - 1 + KB_ROWS) % KB_ROWS ))
                ;;
            "DOWN")
                KB_Y=$(( (KB_Y + 1) % KB_ROWS ))
                ;;
            "LEFT")
                KB_X=$(( (KB_X - 1 + KB_COLS) % KB_COLS ))
                ;;
            "RIGHT")
                KB_X=$(( (KB_X + 1) % KB_COLS ))
                ;;
            "A")
                # Select character
                local char=$(get_char_at $KB_X $KB_Y)
                INPUT_TEXT="${INPUT_TEXT}${char}"
                ;;
            "Y")
                # Backspace
                if [ -n "$INPUT_TEXT" ]; then
                    INPUT_TEXT=$(echo "$INPUT_TEXT" | sed 's/.$//')
                fi
                ;;
            "X")
                # Space
                INPUT_TEXT="${INPUT_TEXT} "
                ;;
            "START")
                # Send message
                if [ -n "$INPUT_TEXT" ]; then
                    return 0
                fi
                ;;
            "B")
                # Exit
                return 1
                ;;
        esac
    done
}

# Main chat loop
main() {
    # Clear old context on fresh start
    # rm -f "$CONTEXT_FILE"

    display -t "GPT-2 Chat

D-pad: move cursor
A: select letter
Y: backspace  X: space
START: send message
B: exit

Press A to start..." -s 22 -p 80 --timeout 0

    acknowledge

    while true; do
        # Get user input via keyboard
        if ! keyboard_input_loop; then
            break
        fi

        local user_message="$INPUT_TEXT"

        # Show thinking message
        display -t "You: $user_message

Thinking..." -s 22 -p 120 --timeout 0

        # Generate response
        local response=$(generate_response "$user_message")

        # Save to context
        add_to_context "User" "$user_message"
        add_to_context "AI" "$response"

        # Display response
        display -t "You: $user_message

AI: $response

Press A to continue..." -s 18 -p 60 --timeout 0

        acknowledge
    done

    display -t "Chat ended. Goodbye!" -d 2
    auto_regen_tmp_update
}

main "$@"
