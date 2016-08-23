/************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * View Name       : XXCMN_S_BATCH_IF_ROUTING_V
 * Description     : �l�Z�b�g�pVIEW�iXXCMN_S_BATCH_IF_ROUTING�j
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2016/06/28    1.0   S.Yamashita      �V�K�쐬
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcmn_s_batch_if_routing_v
(
  routing_no
 ,routing_name
)
AS
SELECT ROUTING_NO  AS routing_no
      ,(SELECT grt.routing_desc
        FROM   gmd_routings_tl grt   
        WHERE  grb.routing_id = grt.routing_id
        AND    grt.language   = USERENV('LANG')
       )           AS routing_name
FROM gmd_routings_b grb
where attribute22 = 'Y'
;
--
COMMENT ON COLUMN xxcmn_s_batch_if_routing_v.routing_no   IS '�H���ԍ�';
COMMENT ON COLUMN xxcmn_s_batch_if_routing_v.routing_name IS '�H����';
--
COMMENT ON TABLE  xxcmn_s_batch_if_routing_v IS '�l�Z�b�g�pVIEW�iXXCMN_S_BATCH_IF_ROUTING�j';
