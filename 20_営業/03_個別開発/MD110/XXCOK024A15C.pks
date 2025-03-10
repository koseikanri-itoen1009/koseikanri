CREATE OR REPLACE PACKAGE APPS.XXCOK024A15C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A15 (spec)
 * Description      : TÁì¬API(APâ®x¥)
 * MD.050           : TÁì¬API(APâ®x¥) MD050_COK_024_A15
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 RJgÀst@Co^vV[W
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/04/28    1.0   Y.Nakajima       mainVKì¬
 *
 *****************************************************************************************/
--
  --RJgÀst@Co^vV[W
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2          -- G[bZ[W #Åè#
   ,retcode                         OUT    VARCHAR2          -- G[R[h     #Åè#
   ,ov_recon_slip_num               OUT    VARCHAR2          -- x¥`[Ô
   ,iv_recon_base_code              IN     VARCHAR2          -- x¥¿_
   ,id_recon_due_date               IN     DATE              -- x¥\èú
   ,id_gl_date                      IN     DATE              -- GLL ú
   ,od_target_date_end              OUT    DATE              -- ÎÛúÔ(TO)
   ,iv_payee_code                   IN     VARCHAR2          -- x¥æR[h
   ,iv_invoice_number               IN     VARCHAR2          -- â®¿Ô
   ,iv_terms_name                   IN     VARCHAR2          -- x¥ð
   ,id_invoice_date                 IN     DATE              -- ¿út
   ,iv_target_data_type             IN     VARCHAR2          -- ÎÛf[^íÞ
  );
END XXCOK024A15C;
/
