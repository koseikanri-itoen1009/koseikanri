CREATE OR REPLACE PACKAGE XXWSH920001C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920001C(spec)
 * Description      : ¶Y¨¬(øAzÔ)
 * MD.050           : o×Eø/zÔF¶Y¨¬¤Êio×EÚ®¼øj T_MD050_BPO_920
 * MD.070           : o×Eø/zÔF¶Y¨¬¤Êio×EÚ®¼øj T_MD070_BPO92A
 * Version          : 1.15
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 * main                 RJgÀst@Co^vV[W
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/12   1.0   Oracle yc Î   ñì¬
 *  2008/04/23   1.1   Oracle yc Î   àÏXv63,65Î
 *  2008/05/30   1.2   Oracle k¦ ³v eXgsïÎ
 *  2008/05/31   1.3   Oracle k¦ ³v eXgsïÎ
 *  2008/06/02   1.4   Oracle k¦ ³v eXgsïÎ
 *  2008/06/05   1.5   Oracle k¦ ³v eXgsïÎ
 *  2008/06/12   1.6   Oracle k¦ ³v eXgsïÎ
 *  2008/07/15   1.7   Oracle k¦ ³v ST#449Î
 *  2008/07/16   1.8   Oracle k¦ ³v ÏXv#93Î
 *  2008/07/25   1.9   Oracle k¦ ³v eXgsïC³
 *  2008/09/08   1.10  Oracle Å¼ º\   PT 6-1_28 wE44 Î
 *  2008/09/10   1.11  Oracle Å¼ º\   PT 6-1_28 wE44 C³
 *  2008/09/17   1.12  Oracle Å¼ º\   TE080_BPO540wE5Î
 *  2008/09/18   1.13  Oracle Å¼ º\   TE080_BPO920wE5Î
 *  2008/09/19   1.14  Oracle Å¼ º\   TE080_BPO920wE4Î
 *  2008/10/27   1.15  Oracle É¡ ÐÆÝ eXgwE325Î
 *****************************************************************************************/
--
  --RJgÀst@Co^vV[W
  PROCEDURE main(
    errbuf                OUT NOCOPY   VARCHAR2,         -- G[bZ[W #Åè#
    retcode               OUT NOCOPY   VARCHAR2,         -- G[R[h     #Åè#
    iv_item_class         IN           VARCHAR2,         -- ¤iæª
    iv_action_type        IN           VARCHAR2,         -- íÊ
    iv_block1             IN           VARCHAR2,         -- ubNP
    iv_block2             IN           VARCHAR2,         -- ubNQ
    iv_block3             IN           VARCHAR2,         -- ubNR
    iv_deliver_from_id    IN           VARCHAR2,           -- oÉ³
    iv_deliver_type       IN           VARCHAR2,           -- oÉ`Ô
    iv_deliver_date_from  IN           VARCHAR2,         -- oÉúFrom
    iv_deliver_date_to    IN           VARCHAR2          -- oÉúTo
  );
END XXWSH920001C;
/
