# Island

Widget do Plasma 6 para o painel: relógio com dia da semana e controle de mídia.

- Clique no relógio: abre o calendário do mês.
- Clique na mídia (aparece quando algo toca): abre o card do player com capa e controles.
- Ignora players de navegador (Brave, Firefox, Chrome etc.) e KDE Connect, só mostra apps de música.

## Requisitos

- Plasma 6
- `playerctl`
- `python3`

## Instalação

```sh
git clone https://github.com/egionCode/plasma-island ~/.local/share/plasma/plasmoids/com.egion.island
```

Depois adicione o widget "Island" ao painel (ou reinicie o shell com `kquitapp6 plasmashell && kstart plasmashell`).

## Licença

MIT
