# Seguimiento semanal

App para preparar y llevar el 1:1 semanal. Cubre cuatro cosas:

- **Proyectos / rocks / tareas** — semáforo, avance, próximo paso, estado de la semana y lo hablado en la reunión.
- **Cuentas en tres niveles** — histórico, implementación y potencial. El semáforo general de la cuenta se calcula solo: es el peor de los tres.
- **Status del equipo** — cómo viene cada persona y el avance de sus objetivos.
- **Mis tareas** — lista personal por marca, con tareas que se repiten solas y un resumen semanal con gráficos.

Además: qué cambió respecto de la semana pasada, alertas de lo que se arrastra en rojo, heatmap de las últimas 12 semanas, reporte de la semana en texto y buscador sobre todo el historial.

## Cómo funciona

Un solo archivo `index.html`, sin dependencias, sin build y sin backend.

Los datos se guardan en el **`localStorage` del navegador donde la abrís**, no dentro del archivo. Eso significa que:

- Publicar la app no publica ningún dato.
- Los datos **no viajan** entre navegadores ni entre dispositivos. Abrirla en el celular la muestra vacía.
- Para mudar los datos de un lado a otro: **Config → Exportar respaldo**, y en el destino **Config → Importar respaldo**.

Conviene exportar cada tanto: si se limpian los datos de navegación, no hay vuelta atrás. La app avisa sola cuando pasaron más de 14 días sin respaldo.

## Atajos

| Tecla | Qué hace |
|---|---|
| `1` `2` `3` | Pinta el semáforo en verde / amarillo / rojo |
| `0` | Vacía el semáforo |
| `Tab` o flechas | Se mueve entre semáforos |
| `Ctrl+K` | Buscador global |
| `←` `→` | Semana anterior / siguiente |
