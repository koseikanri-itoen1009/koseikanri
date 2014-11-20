UPDATE xxcfr_invoice_lines  xil
SET    xil.cutoff_date = (SELECT temp.cutoff_date
                          FROM   xxcfr_invoice_headers temp
                          WHERE  temp.invoice_id = xil.invoice_id
                       )
;
/
COMMIT;
/
--
