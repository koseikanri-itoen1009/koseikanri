CREATE OR REPLACE PACKAGE apps.xxcmn_common5_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name           : xxcmn_common5_pkg(body)
 * Description            : ���ʊ֐�5
 * MD.070(CMD.050)        : T_MD050_BPO_000_���ʊ֐�5.xls
 * Version                : 1.1
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  get_use_by_date       F    DATE  �ܖ������擾�֐�
 *  chek_lot_unit_price   F    NUM   ���ׂ��̃��b�g�P���ύX�`�F�b�N
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/02/22    1.0   H.Sasaki        �V�K�쐬(E_�{�ғ�_14859)
 *  2020/07/30    1.1   Y.Shoji         E_�{�ғ�_16375�Ή�
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
-- Ver_1.1 E_�{�ғ�_16375 ADD Start
  FUNCTION  chek_lot_unit_price(
      id_base_date          IN DATE       --  1.���
    , in_lot_id             IN NUMBER     --  2.���b�gID
    , iv_unit_price         IN VARCHAR2   --  3.�P��
  ) RETURN NUMBER;
--
-- Ver_1.1 E_�{�ғ�_16375 ADD End
END xxcmn_common5_pkg;
/
