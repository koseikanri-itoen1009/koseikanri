create or replace FUNCTION xxwsh_loader_id_func(
  iv_head_line_type        IN VARCHAR2,    -- �w�b�_����׋敪
  iv_lines_head_line_type  IN VARCHAR2,    -- �w�b�_����׋敪(����)
  iv_eos_data_type         IN VARCHAR2,    -- �f�[�^���
  iv_delivery_no           IN VARCHAR2,    -- �z����
  iv_order_source_ref      IN VARCHAR2     -- �˗���
  )
  RETURN NUMBER
IS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Proc Name              : xxwsh_loader_id_func
 * Description            : SQL*Loader�pID���s�֐�
 * MD.070(CMD.050)        : �Ȃ�
 * Version                : 1.1
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/05/19   1.0   ORACLE �Ŗ����\  �V�K�쐬
 *  2008/06/11   1.1   ORACLE �y�c�M    LINE����HEADER_ID�擾�s��Ή�
 *****************************************************************************************/
--
  -- ===============================
  -- ���[�U�[�錾��
  -- ===============================
  -- *** ���[�J���萔 ***
  cv_headers          VARCHAR2(150)        := 'HEADERS';  -- �w�b�_
  cv_lines            VARCHAR2(150)        := 'LINES';    -- ����
  cv_delivery_no_null CONSTANT VARCHAR2(1) := 'X';        -- �z��No��NULL���̕ϊ�����
--
  -- *** ���[�J���ϐ� ***
  ln_seq            NUMBER;                               -- �̔Ԕԍ�
--
BEGIN
  -- �w�b�_�̃w�b�_ID���擾
  IF (iv_head_line_type = cv_headers) THEN
    SELECT xxwsh_shipping_headers_if_s1.NEXTVAL INTO ln_seq FROM dual;
  -- ���ׂ̃w�b�_ID���擾
  ELSIF (iv_head_line_type = cv_lines) AND
          (iv_lines_head_line_type = cv_headers) THEN
--    SELECT xxwsh_shipping_headers_if_s1.CURRVAL INTO ln_seq FROM dual;
    SELECT NVL(MAX(header_id),0)              -- MAX�֐��ɂ��A�擾�ł��Ȃ��ꍇ��0��Ԃ�
      INTO ln_seq
      FROM XXWSH_SHIPPING_HEADERS_IF
     WHERE EOS_DATA_TYPE = iv_eos_data_type
       AND NVL(DELIVERY_NO,cv_delivery_no_null) = NVL(iv_delivery_no,cv_delivery_no_null)
       AND ORDER_SOURCE_REF = iv_order_source_ref;
-- ���ׂ̖���ID���擾
  ELSIF (iv_head_line_type = cv_lines) AND
          (iv_lines_head_line_type = cv_lines) THEN
    SELECT xxwsh_shipping_lines_if_s1.NEXTVAL INTO ln_seq FROM dual;
--
  ELSE
    ln_seq := NULL;
--
  END IF;
--
  RETURN ln_seq;
--
END xxwsh_loader_id_func;
/
