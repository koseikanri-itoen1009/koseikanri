CREATE OR REPLACE PACKAGE xxcmn_common4_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2012. All rights reserved.
 *
 * Package Name           : xxcmn_common4_pkg(spec)
 * Description            : ���ʊ֐�4
 * MD.070(CMD.050)        : T_MD050_BPO_000_���ʊ֐�4.xls
 * Version                : 1.0
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  get_syori_date         F  DATE  �������t�擾
 *  get_purge_period       F  NUM   �o�b�N�A�b�v����/�p�[�W���Ԏ擾�֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/18   1.00  SCSK �{�{����    �V�K�쐬
 *
 *****************************************************************************************/
--
  -- ===============================
  -- �O���[�o���^
  -- ===============================
--
--
  -- ===============================
  -- �v���V�[�W������уt�@���N�V����
  -- ===============================
--
  -- �������t�擾
  FUNCTION get_syori_date RETURN DATE;
--

  -- �o�b�N�A�b�v����/�p�[�W���Ԏ擾�֐�
  FUNCTION get_purge_period (
    iv_purge_type IN VARCHAR2,    --PURGE_TYPE(0:�p�[�W�������� 1:�o�b�N�A�b�v��������)
    iv_purge_code IN VARCHAR2)    --PURGE_CODE
    RETURN NUMBER;
--
--
END xxcmn_common4_pkg;
/
