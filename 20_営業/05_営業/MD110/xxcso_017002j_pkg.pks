CREATE OR REPLACE PACKAGE apps.xxcso_017002j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_017002j_pkg(SPEC)
 * Description      : ���ϖ��דo�^
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  set_quote_lines             P          ���ϖ��דo�^�p�v���V�[�W��
 *  set_sales_status            P          �̔��p���ς̃X�e�[�^�X�X�V�p�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/06    1.0   R.Oikawa          �V�K�쐬
 *
 *****************************************************************************************/
--
   -- ���ϖ��דo�^�p�v���V�[�W��
  PROCEDURE set_quote_lines(
    iv_select_flg                 IN  VARCHAR2,           -- �I��
    in_quote_line_id              IN  NUMBER,             -- ���ϖ��ׂh�c
    in_reference_quote_line_id    IN  NUMBER,             -- �Q�Ɨp���ϖ��ׂh�c
    iv_quotation_price            IN  VARCHAR2,           -- ���l
    iv_sales_discount_price       IN  VARCHAR2,           -- ����l��
    iv_usuall_net_price           IN  VARCHAR2,           -- �ʏ�m�d�s���i
    iv_this_time_net_price        IN  VARCHAR2,           -- ����m�d�s���i
    iv_amount_of_margin           IN  VARCHAR2,           -- �}�[�W���z
    iv_margin_rate                IN  VARCHAR2,           -- �}�[�W����
    id_quote_start_date           IN  DATE,               -- ���ԁi�J�n�j
    iv_remarks                    IN  VARCHAR2,           -- ���l
    iv_line_order                 IN  VARCHAR2,           -- ���я�
    in_quote_header_id            IN  NUMBER              -- ���σw�b�_�[�h�c
  );
--
   -- �̔��p���ς̃X�e�[�^�X�X�V�p�v���V�[�W��
  PROCEDURE set_sales_status(
    in_reference_quote_header_id    IN  NUMBER            -- �Q�Ɨp���σw�b�_�[�h�c
  );
--
END xxcso_017002j_pkg;
/
