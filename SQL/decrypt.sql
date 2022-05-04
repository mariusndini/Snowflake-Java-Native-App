create or replace procedure SUMMIT_LEGEND_APP.APP_SCHEMA.DECRYPT(SALT varchar, ENCODED varchar  )
RETURNS STRING
LANGUAGE JAVASCRIPT
EXECUTE AS OWNER
AS $$
{
    const textToChars = (text) => text.split("").map((c) => c.charCodeAt(0));
    const applySaltToChar = (code) => textToChars(SALT).reduce((a, b) => a ^ b, code);
    return ENCODED
      .match(/.{1,2}/g)
      .map((hex) => parseInt(hex, 16))
      .map(applySaltToChar)
      .map((charCode) => String.fromCharCode(charCode))
      .join("");
}
$$;