// DistriMax - funciones globales (todo en el objeto DM y alguna suelta, por historia)
var DM = DM || {};

DM.idiomaTabla = {
    decimal: ',',
    thousands: '.',
    emptyTable: 'No hay registros',
    info: 'Mostrando _START_ a _END_ de _TOTAL_ registros',
    infoEmpty: 'Sin registros',
    infoFiltered: '(filtrado de _MAX_)',
    lengthMenu: 'Mostrar _MENU_',
    loadingRecords: 'Cargando...',
    processing: 'Procesando...',
    search: 'Filtrar:',
    zeroRecords: 'Ningún registro coincide con el filtro',
    paginate: { first: 'Primero', last: 'Último', next: 'Siguiente', previous: 'Anterior' }
};

DM.tabla = function (selector, opciones) {
    var o = $.extend({ language: DM.idiomaTabla, pageLength: 25, autoWidth: false }, opciones || {});
    return $(selector).DataTable(o);
};

DM.formatoMoneda = function (valor) {
    var n = Math.round(parseFloat(valor) || 0).toString();
    return '$' + n.replace(/\B(?=(\d{3})+(?!\d))/g, '.');
};

function calcularDV(nit) {
    if (!nit) return '';
    nit = nit.replace(/[^0-9]/g, '');
    var pesos = [3, 7, 13, 17, 19, 23, 29, 37, 41, 43, 47, 53, 59, 67, 71];
    var suma = 0;
    for (var i = 0; i < nit.length; i++) {
        suma += parseInt(nit.charAt(nit.length - 1 - i), 10) * pesos[i];
    }
    var r = suma % 11;
    return (r > 1 ? 11 - r : r).toString();
}
