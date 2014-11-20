CREATE OR REPLACE PACKAGE XXCFF003A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF003A03C(spec)
 * Description      : ���[�X��ޔ���
 * MD.050           : MD050_CFF_003_A03_���[�X��ޔ���
 * Version          : 1.0
 *
 * Program List
 * --------------------      ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * --------------------      ---- ----- --------------------------------------------------
 *  main                      P          �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-04    1.0   SCS ���q �G�K    �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �v���V�[�W���錾�� START   #######################
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    iv_lease_type                  IN  VARCHAR2,    -- 1.���[�X�敪
    in_payment_frequency           IN  NUMBER,      -- 2.�x����
    in_first_charge                IN  NUMBER,      -- 3.���񌎊z���[�X��
    in_second_charge               IN  NUMBER,      -- 4.�Q��ڈȍ~���z���[�X��
    in_estimated_cash_price        IN  NUMBER,      -- 5.���ό����w�����z
    in_life_in_months              IN  NUMBER,      -- 6.�@��ϗp�N��
    id_contract_ym                 IN  DATE,        -- 7.�_��N��
    ov_lease_kind                  OUT VARCHAR2,    -- 8.���[�X���
    on_present_value_discount_rate OUT NUMBER,      -- 9.���݉��l������
    on_present_value               OUT NUMBER,      -- 10.���݉��l
    on_original_cost               OUT NUMBER,      -- 11.�擾���z
    on_calc_interested_rate        OUT NUMBER,      -- 12.�v�Z���q��
    ov_errbuf                      OUT VARCHAR2,    -- �G���[�E���b�Z�[�W
    ov_retcode                     OUT VARCHAR2,    -- ���^�[���E�R�[�h
    ov_errmsg                      OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
--
END XXCFF003A03C
;
/
