CREATE OR REPLACE PACKAGE XXCFF003A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF003A03C(spec)
 * Description      : ���[�X��ޔ���
 * MD.050           : MD050_CFF_003_A03_���[�X��ޔ���
 * Version          : 1.4
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
 *  2016-08-10    1.1   SCSK �m�� �d�l   [E_�{�ғ�_13658]���̋@�ϗp�N���ύX�Ή�
 *  2018-09-10    1.4   SCSK ���X�؍G�V  E_�{�ғ�_14830 �ǉ��Ή�
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
-- Ver.1.1 ADD Start
    iv_lease_class                 IN  VARCHAR2,    -- 8.���[�X���
-- Ver.1.1 ADD End
--  V1.4 2018/09/10 Added START
    iv_process_flag                IN  VARCHAR2 DEFAULT NULL,       --  �����敪
--  V1.4 2018/09/10 Added END
    ov_lease_kind                  OUT VARCHAR2,    -- 9.���[�X���
    on_present_value_discount_rate OUT NUMBER,      -- 10.���݉��l������
    on_present_value               OUT NUMBER,      -- 11.���݉��l
    on_original_cost               OUT NUMBER,      -- 12.�擾���z
    on_calc_interested_rate        OUT NUMBER,      -- 13.�v�Z���q��
-- Ver.1.1 ADD Start
    on_original_cost_type1         OUT NUMBER,      -- 14.���[�X���z_���_��
    on_original_cost_type2         OUT NUMBER,      -- 15.���[�X���z_�ă��[�X
-- Ver.1.1 ADD End
    ov_errbuf                      OUT VARCHAR2,    -- �G���[�E���b�Z�[�W
    ov_retcode                     OUT VARCHAR2,    -- ���^�[���E�R�[�h
    ov_errmsg                      OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
--
END XXCFF003A03C
;
/
