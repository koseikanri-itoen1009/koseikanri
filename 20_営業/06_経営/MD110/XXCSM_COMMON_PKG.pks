CREATE OR REPLACE PACKAGE xxcsm_common_pkg
IS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcsm_common_pkg(spec)
 * Description            :
 * MD.070                 : MD070_IPO_CSM_���ʊ֐�
 * Version                : 1.0
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  get_yearplan_calender      P          �N�Ԍv��J�����_�擾�֐�
 *  get_employee_info          P          �]�ƈ����擾�֐�
 *  get_employee_foothold      P          �]�ƈ��ݐЋ��_�R�[�h�擾�֐�
 *  get_login_user_foothold    P          ���O�C�����[�U�[�ݐЋ��_�R�[�h�擾�֐�
 *  year_item_plan_security    P          �N�ԏ��i�v��Z�L�����e�B����p�֐�
 *  get_year_month             P          �N�x�Z�o�֐�
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008-11-27    1.0  T.Tsukino       �V�K�쐬
 *****************************************************************************************/
--
    -- ==============================
    -- �O���[�o��RECORD�^
    -- =============================
   -- ���_���X�g���R�[�h
    TYPE g_kyoten_rtype IS RECORD(
      kyoten_cd           fnd_flex_values.flex_value%TYPE       -- ���_�R�[�h
     ,kyoten_nm           fnd_flex_values_tl.description%TYPE   -- ���_����
       );
    --  ���_���X�g�e�[�u��
    TYPE g_kyoten_ttype IS TABLE OF g_kyoten_rtype INDEX BY BINARY_INTEGER;
--
  /**********************************************************************************
   * Procedure  Name   : get_yearplan_calender
   * Description       : �N�Ԍv��J�����_�擾�֐�
   ***********************************************************************************/
  PROCEDURE get_yearplan_calender(
               id_comparison_date IN  DATE                                      -- ���t
              ,ov_status          OUT NOCOPY VARCHAR2                           -- ��������(0�F����A1�F�ُ�
              ,on_active_year     OUT NUMBER                                    -- �Ώ۔N�x
              ,ov_retcode         OUT NOCOPY VARCHAR2                           -- ���^�[���R�[�h
              ,ov_errbuf          OUT NOCOPY VARCHAR2                           -- �G���[���b�Z�[�W
              ,ov_errmsg          OUT NOCOPY VARCHAR2                           -- ���[�U�[�E�G���[���b�Z�[�W
              );
--
  /**********************************************************************************
   * Procedure Name   : get_employee_info
   * Description      : �]�ƈ����擾�֐�
   ***********************************************************************************/
  PROCEDURE get_employee_info(
               iv_employee_code   IN  VARCHAR2                                  --�]�ƈ��R�[�h
              ,id_comparison_date IN  DATE                                      --���ߓ��Ɣ�r������t
              ,ov_capacity_code   OUT NOCOPY VARCHAR2                           --���i�R�[�h
              ,ov_duty_code       OUT NOCOPY VARCHAR2                           --�E���R�[�h
              ,ov_job_code        OUT NOCOPY VARCHAR2                           --�E��R�[�h
              ,ov_new_old_type    OUT NOCOPY VARCHAR2                           --�V���t���O�i1�F�V�A2�F���j
              ,ov_retcode         OUT NOCOPY VARCHAR2                           -- ���^�[���R�[�h
              ,ov_errbuf          OUT NOCOPY VARCHAR2                           --�G���[���b�Z�[�W
              ,ov_errmsg          OUT NOCOPY VARCHAR2                           --���[�U�[�E�G���[���b�Z�[�W
              );
--
  /**********************************************************************************
   * Procedure Name   : get_employee_foothold
   * Description      : �]�ƈ��ݐЋ��_�R�[�h�擾�֐�
   ***********************************************************************************/
  PROCEDURE get_employee_foothold(
               iv_employee_code   IN  VARCHAR2                    --�]�ƈ��R�[�h 
              ,id_comparison_date IN  DATE                        --���ߓ��Ɣ�r������t
              ,ov_foothold_code   OUT NOCOPY VARCHAR2             --���_�R�[�h
              ,ov_retcode         OUT NOCOPY VARCHAR2             -- ���^�[���R�[�h
              ,ov_errbuf          OUT NOCOPY VARCHAR2             --�G���[���b�Z�[�W
              ,ov_errmsg          OUT NOCOPY VARCHAR2             --���[�U�[�E�G���[���b�Z�[�W
              );
--
  /**********************************************************************************
   * Procedure Name   : get_login_user_foothold
   * Description      : ���O�C�����[�U�[�ݐЋ��_�R�[�h�擾�֐�
   ***********************************************************************************/
  PROCEDURE get_login_user_foothold(
               in_user_id       IN NUMBER                                       --���[�UID
              ,ov_foothold_code OUT NOCOPY VARCHAR2                             --���_�R�[�h
              ,ov_employee_code OUT NOCOPY VARCHAR2                             --�]�ƈ��R�[�h
              ,ov_retcode       OUT NOCOPY VARCHAR2                             -- ���^�[���R�[�h
              ,ov_errbuf        OUT NOCOPY VARCHAR2                             --�G���[���b�Z�[�W
              ,ov_errmsg        OUT NOCOPY VARCHAR2                             --���[�U�[�E�G���[���b�Z�[�W
              );
--
  /**********************************************************************************
   * Procedure  Name   : year_item_plan_security
   * Description       : �N�ԏ��i�v��Z�L�����e�B����p�֐�
   ***********************************************************************************/
  PROCEDURE year_item_plan_security(
               in_user_id          IN  NUMBER
              ,ov_lv6_kyoten_list  OUT NOCOPY VARCHAR2
              ,ov_retcode          OUT NOCOPY VARCHAR2         -- ���^�[���R�[�h
              ,ov_errbuf           OUT NOCOPY VARCHAR2          --�G���[���b�Z�[�W
              ,ov_errmsg           OUT NOCOPY VARCHAR2          --���[�U�[�E�G���[���b�Z�[�W              
              );
--
  /**********************************************************************************
   * Procedure  Name   : get_year_month
   * Description       : �N�x�Z�o�֐�
   ***********************************************************************************/
  PROCEDURE get_year_month(
               iv_process_years IN VARCHAR2
              ,ov_year          OUT NOCOPY VARCHAR2
              ,ov_month         OUT NOCOPY VARCHAR2
              ,ov_retcode       OUT NOCOPY VARCHAR2
              ,ov_errbuf        OUT NOCOPY VARCHAR2
              ,ov_errmsg        OUT NOCOPY VARCHAR2
              );              
--
  /**********************************************************************************
   * Procedure  Name   : get_kyoten_cd_lv6
   * Description       : �c�ƕ���z�z�������_���X�g�̎擾
   ***********************************************************************************/
  PROCEDURE get_kyoten_cd_lv6(
               iv_kyoten_cd         IN VARCHAR2
              ,iv_kaisou            IN VARCHAR2
              ,o_kyoten_list_tab    OUT g_kyoten_ttype
              ,ov_retcode           OUT NOCOPY VARCHAR2
              ,ov_errbuf            OUT NOCOPY VARCHAR2
              ,ov_errmsg            OUT NOCOPY VARCHAR2
              );
END xxcsm_common_pkg;
/

