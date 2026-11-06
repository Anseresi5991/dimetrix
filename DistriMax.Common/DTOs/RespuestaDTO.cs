namespace DistriMax.Common.DTOs
{
    // AP-11: "formato estándar" de respuesta... que solo usan algunos endpoints.
    // Propiedades en minúscula porque "así lo pidió el front" en 2017.
    public class RespuestaDTO
    {
        public bool ok { get; set; }
        public string mensaje { get; set; }
        public object data { get; set; }
    }
}
