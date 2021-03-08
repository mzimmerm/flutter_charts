#! /bin/bash

# dcdg is a package which generates uml
#   if installed 'globally', it will add executable to ~~/.pub-cache/bin~
#   this dir should be added to path 
# flutter pub global activate dcdg # Installs ~/.pub-cache/bin/dcdg executable 
# export PATH="$PATH":"$HOME/.pub-cache/bin"
# cd my_package
flutter pub global run dcdg -o flutter_charts.plantuml # creates a file with plantuml text
java -jar ~/software/java-based/plantuml/plantuml.1.2017.12.jar flutter_charts.plantuml # Generates flutter_charts.png UML
