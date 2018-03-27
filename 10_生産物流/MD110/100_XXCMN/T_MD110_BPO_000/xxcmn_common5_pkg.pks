CREATE OR REPLACE PACKAGE apps.xxcmn_common5_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name           : xxcmn_common5_pkg(body)
 * Description            : ���ʊ֐�5
 * MD.070(CMD.050)        : T_MD050_BPO_000_���ʊ֐�5.xls
 * Version                : 1.0
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  get_use_by_date       F    DATE  �ܖ������擾�֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/02/22    1.0   H.Sasaki        �V�K�쐬(E_�{�ғ�_14859)
 *
 *****************************************************************************************/
--
  -- ===============================
  -- �v���V�[�W������уt�@���N�V����
  -- ===============================
--
  FUNCTION  get_use_by_date(
      id_producted_date     IN DATE       --  1.������
    , iv_expiration_type    IN VARCHAR2   --  2.�\���敪
    , in_expiration_day     IN NUMBER     --  3.�ܖ�����
    , in_expiration_month   IN NUMBER     --  4.�ܖ�����(��)
  ) RETURN DATE;
--
END xxcmn_common5_pkg;
/
