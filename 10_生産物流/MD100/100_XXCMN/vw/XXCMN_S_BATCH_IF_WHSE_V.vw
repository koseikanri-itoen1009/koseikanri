/************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * View Name       : XXCMN_S_BATCH_IF_WHSE_V
 * Description     : �l�Z�b�g�pVIEW�iXXCMN_S_BATCH_IF_WHSE�j
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2016/06/24    1.0   S.Yamashita      �V�K�쐬
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcmn_s_batch_if_whse_v
(
  whse_code
 ,whse_name
)
AS
  SELECT DISTINCT
    iwm.whse_code   AS whse_code -- �q�ɃR�[�h
   ,iwm.whse_name   AS whse_name -- �q�ɖ���
  FROM
    gmd_routings_b  grb -- �H���}�X�^
   ,ic_whse_mst     iwm -- OPM�q�Ƀ}�X�^
  WHERE
        grb.attribute22 = 'Y'  -- ���Y�o�b�`���IF�Ώۃt���O
  AND   grb.attribute21 = iwm.whse_code -- �q�ɃR�[�h
;
--
COMMENT ON COLUMN xxcmn_s_batch_if_whse_v.whse_code IS '�q�ɃR�[�h';
COMMENT ON COLUMN xxcmn_s_batch_if_whse_v.whse_name IS '�q�ɖ���';
--
COMMENT ON TABLE  xxcmn_s_batch_if_whse_v IS '�l�Z�b�g�pVIEW�iXXCMN_S_BATCH_IF_WHSE�j';
