
index.html: src/containers-presentation.md img/workflow_diagram.svg
	pandoc --to=revealjs --standalone \
        --output=$@ src/containers-presentation.md \
        -V revealjs-url=https://revealjs.com \
        -V theme=white \
        -V history=true \
        -V center=false \
        -V transition=none \
        -V controlsTutorial=false
