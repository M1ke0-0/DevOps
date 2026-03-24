show_usage() {
    echo "Использование: $0 [-p] <имя_файла_или_шаблон>"
    echo "  -p    Использовать параметр как шаблон (подстроку) для поиска файлов."
    exit 1
}

use_pattern=false

while getopts "p" opt; do
    case $opt in
        p) use_pattern=true ;;
        *) show_usage ;;
    esac
done

shift $((OPTIND - 1))

TARGET=$1

if [ -z "$TARGET" ]; then
    show_usage
fi

if [ "$use_pattern" = true ]; then
    echo "Режим шаблона: ищем файлы, содержащие '$TARGET'..."
    
    for file in ./*; do
        if [[ -f "$file" && "$file" == *"$TARGET"* ]]; then
            echo "Удаление совпадения: $file"
            rm "$file"
        fi
    done
else
    FILE_PATH="./$TARGET"
    if [ -f "$FILE_PATH" ]; then
        echo "Удаление файла: $FILE_PATH"
        rm "$FILE_PATH"
    else
        echo "Ошибка: Файл '$FILE_PATH' не найден."
    fi
fi
