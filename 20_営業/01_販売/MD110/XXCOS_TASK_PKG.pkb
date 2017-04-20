CREATE OR REPLACE PACKAGE BODY XXCOS_TASK_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS_TASK_PKG(spec)
 * Description      : ���ʊ֐��p�b�P�[�W(�̔�)
 * MD.070           : ���ʊ֐�    MD070_IPO_COS
 * Version          : 1.6
 *
 * Program List
 * --------------------------- ------ ---------- -----------------------------------------
 *  Name                        Type   Return     Description
 * --------------------------- ------ ---------- -----------------------------------------
 *  task_entry                  P                 �K��E�L�����ѓo�^
 *  
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- --------------------------------------------------
 *  2008/12/12    1.0   T.kitajima       �V�K�쐬
 *  2009/02/18    1.1   T.kitajima       [COS_091]����VD�Ή�
 *  2009/05/18    1.2   T.kitajima       [T1_0652]������񎞂̓o�^���\�[�X�ԍ��K�{����
 *  2009/11/24    1.3   S.Miyakoshi      TASK�f�[�^�擾���̓��t�̏����ύX
 *  2010/11/15    1.4   K.Kiriu          [E_�{�ғ�_05129]�^�X�N�쐬PT�Ή�
 *  2011/03/28    1.5   Oukou            [E_�{�ғ�_00153]HHT�����f�[�^�捞�ُ�I���Ή�
 *  2017/04/12    1.6   Y.Shoji          [E_�{�ғ�_14025]HHT����̃V�X�e�����t�A�g�ǉ��Ή�
 ****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
/* 2011/03/28 Ver1.5 ADD Start */
  -- ���R�[�h���b�N�G���[
  record_lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( record_lock_expt, -54 );
/* 2011/03/28 Ver1.5 ADD End   */
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  global_indispensability_expt    EXCEPTION; -- �K�{�G���[
  global_registration_expt        EXCEPTION; -- �o�^�敪�w��G���[
  global_effective_visi_expt      EXCEPTION; -- �L���K���ԃG���[
  global_get_effective_visi_expt  EXCEPTION; -- �L���K��擾�G���[
  
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS_TASK_PKG';       -- �p�b�P�[�W��
  --�A�v���P�[�V�����Z�k��
  ct_xxcos_appl_short_name        CONSTANT  fnd_application.application_short_name%TYPE
                                            := 'XXCOS';                         -- �̕��Z�k�A�v����
  --�̕����b�Z�[�W
  ct_msg_app_xxcos1_13568         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13568';              -- ���\�[�XID�K�{�G���[���b�Z�[�W
  ct_msg_app_xxcos1_13569         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13569';              -- �p�[�e�BID�K�{�G���[���b�Z�[�W
  ct_msg_app_xxcos1_13570         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13570';              -- �p�[�e�B���̕K�{�G���[���b�Z�[�W
  ct_msg_app_xxcos1_13571         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13571';              -- �K������K�{�G���[���b�Z�[�W
  ct_msg_app_xxcos1_13572         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13572';              -- ������z�K�{�G���[���b�Z�[�W
  ct_msg_app_xxcos1_13573         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13573';              -- �o�^�敪�K�{�G���[���b�Z�[�W
  ct_msg_app_xxcos1_13574         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13574';              -- �o�^���\�[�X�ԍ��K�{�G���[���b�Z�[�W
  ct_msg_app_xxcos1_13575         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13575';              -- �ڋq�X�e�[�^�X�K�{�G���[���b�Z�[�W
  ct_msg_app_xxcos1_13576         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13576';              -- �o�^�敪�w��G���[
  ct_msg_app_xxcos1_13577         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13577';              -- �L���K��敪�`�F�b�N�G���[
  ct_msg_app_xxcos1_13578         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13578';              -- �L���K��敪�擾�G���[
  ct_msg_app_xxcos1_13579         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13579';              -- ���͋敪�K�{�G���[
  ct_msg_app_xxcos1_13580         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13580';              -- �[�i
  ct_msg_app_xxcos1_13581         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13581';              -- ����
  ct_msg_app_xxcos1_13582         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13582';              -- ������z�}�C�i�X�G���[
  ct_msg_app_xxcos1_13589         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-13589';              -- ����
/* 2011/03/28 Ver1.5 ADD Start */
  ct_msg_app_xxcos1_00001         CONSTANT  fnd_new_messages.message_name%TYPE
                                            := 'APP-XXCOS1-00001';              -- ���b�N�G���[
/* 2011/03/28 Ver1.5 ADD End   */

  --�g�[�N��
  cv_tkn_in_param                 CONSTANT  VARCHAR2(100) := 'PARAM';           -- ���̓p�����[�^
  cv_tkn_in_param1                CONSTANT  VARCHAR2(100) := 'PARAM1';          -- ���̓p�����[�^
  cv_tkn_in_param2                CONSTANT  VARCHAR2(100) := 'PARAM2';          -- ���̓p�����[�^
  cv_tkn_in_param3                CONSTANT  VARCHAR2(100) := 'PARAM3';          -- ���̓p�����[�^
/* 2011/03/28 Ver1.5 ADD Start */
  cv_tkn_table                    CONSTANT  VARCHAR2(20)  := 'TABLE';           -- �e�[�u��
/* 2011/03/28 Ver1.5 ADD End   */
  --�o�^�敪
  cv_registration_division_3      CONSTANT  VARCHAR2(1)   := '3';                  -- �[�i���
  cv_registration_division_4      CONSTANT  VARCHAR2(1)   := '4';                  -- �W�����
  cv_registration_division_5      CONSTANT  VARCHAR2(1)   := '5';                  -- ����VD���
  --�L���K��敪
  cv_effective_visit_1            CONSTANT  VARCHAR2(1)   := '1';                  -- �L��
  cv_effective_visit_0            CONSTANT  VARCHAR2(1)   := '0';                  -- �K��
  --�\�[�X����
  cv_source_party                 CONSTANT  VARCHAR2(5)   := 'PARTY';              -- PARTY
  cv_own_typ                      CONSTANT  VARCHAR2(15)  := 'RS_EMPLOYEE';        -- RS_EMPLOYEE
/* 2010/11/15 Ver1.4 Del Start */
--  --�t�H�[�}�b�g
--  cv_trunc_format_dd              CONSTANT  VARCHAR2(2)   := 'DD';                 -- ��
/* 2010/11/15 Ver1.4 Del End   */
  --���͋敪
  cv_input_division_0             CONSTANT  VARCHAR2(1)   := '0';                  -- �_�~�[
  cv_input_division_1             CONSTANT  VARCHAR2(1)   := '1';                  -- �[�i���́EEOS�`�[����
  cv_input_division_2             CONSTANT  VARCHAR2(1)   := '2';                  -- �ԕi����
  cv_input_division_3             CONSTANT  VARCHAR2(1)   := '3';                  -- ���̋@����
  cv_input_division_4             CONSTANT  VARCHAR2(1)   := '4';                  -- ���̋@�ԕi
  cv_input_division_5             CONSTANT  VARCHAR2(1)   := '5';                  -- �t��VD�[�i�E�����z��
  --�폜�t���O
  cd_del_flg_y                    CONSTANT  VARCHAR2(1)   := 'Y';                  -- �폜
  cd_del_flg_n                    CONSTANT  VARCHAR2(1)   := 'N';                  -- �L��
  --�ڍד��e
  cv_details_delivery             CONSTANT VARCHAR2(50)   := xxccp_common_pkg.get_msg(
                                                                iv_application        =>  ct_xxcos_appl_short_name
                                                               ,iv_name               =>  ct_msg_app_xxcos1_13580
                                                             );                    -- �[�i
  cv_details_payment              CONSTANT VARCHAR2(50)   := xxccp_common_pkg.get_msg(
                                                                iv_application        =>  ct_xxcos_appl_short_name
                                                               ,iv_name               =>  ct_msg_app_xxcos1_13581
                                                             );                    -- ����
  cv_details_digestion            CONSTANT VARCHAR2(50)   := xxccp_common_pkg.get_msg(
                                                                iv_application        =>  ct_xxcos_appl_short_name
                                                               ,iv_name               =>  ct_msg_app_xxcos1_13589
                                                             );                    -- ����
  --
/* 2011/03/28 Ver1.5 ADD Start */
  cv_table_task                   CONSTANT  VARCHAR2(20)  := '�^�X�N���';         -- �e�[�u��
/* 2011/03/28 Ver1.5 ADD End   */
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  --==================================
  -- �v���C�x�[�g��t�@���N�V����
  --==================================
--
  /**********************************************************************************
   * Procedure Name   : task_entry
   * Description      : �K��E�L�����ѓo�^
   ***********************************************************************************/
  PROCEDURE task_entry(
               ov_errbuf          OUT NOCOPY  VARCHAR2                --�G���[���b�Z�[�W
              ,ov_retcode         OUT NOCOPY  VARCHAR2                --���^�[���R�[�h
              ,ov_errmsg          OUT NOCOPY  VARCHAR2                --���[�U�[�E�G���[�E���b�Z�[�W
              ,in_resource_id     IN          NUMBER    DEFAULT NULL  --���\�[�XID
              ,in_party_id        IN          NUMBER    DEFAULT NULL  --�p�[�e�BID
              ,iv_party_name      IN          VARCHAR2  DEFAULT NULL  --�p�[�e�B����
              ,id_visit_date      IN          DATE      DEFAULT NULL  --�K�����
              ,iv_description     IN          VARCHAR2  DEFAULT NULL  --�ڍד��e
              ,in_sales_amount    IN          NUMBER    DEFAULT NULL  --������z(2008/12/12 �ǉ�)
              ,iv_input_division  IN          VARCHAR2  DEFAULT NULL  --���͋敪(2008/12/17 �ǉ�)
              ,iv_entry_class     IN          VARCHAR2  DEFAULT NULL  --�c�e�e�P�Q�i�o�^�敪�j
              ,iv_source_no       IN          VARCHAR2  DEFAULT NULL  --�c�e�e�P�R�i�o�^���\�[�X�ԍ��j
              ,iv_customer_status IN          VARCHAR2  DEFAULT NULL  --�c�e�e�P�S�i�ڋq�X�e�[�^�X�j
            )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'task_entry'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    lv_key_info            VARCHAR2(5000);                         --�L�[���
    lv_description         VARCHAR2(5000);                         --�ڍ�
    lv_effective_visi      VARCHAR2(1);                            --�L���K��敪
/* 2011/03/28 Ver1.5 ADD Start */
    ln_task_cnt            NUMBER;                                 --�^�X�N�f�[�^����
    lv_target_task_id      jtf_tasks_b.task_id%TYPE;               --�^�X�NID
/* 2011/03/28 Ver1.5 ADD End   */
    lt_msg_num             fnd_new_messages.message_name%TYPE;     --���b�Z�[�W�R�[�h
    lt_task_effective_visi jtf_tasks_b.attribute11%TYPE;           --TASK�L���K��敪
    lt_task_id             jtf_tasks_b.task_id%TYPE;               --�^�X�NID
    lt_ovn                 jtf_tasks_b.object_version_number%TYPE; --�I�u�W�F�N�g���@�[�W����No
/* 2010/11/15 Ver1.4 Add Start */
    ld_visit_date          DATE;                                   --�K���(�L���K��敪�`�F�b�N�����p)
/* 2010/11/15 Ver1.4 Add End   */
/* 2011/03/28 Ver1.5 ADD Start */
--
    -- *** ���[�J���E�J�[�\�� ***
    --�^�X�N���
    CURSOR task_data_cur(it_task_id  jtf_tasks_b.task_id%TYPE)
    IS
      SELECT
             /*+
               INDEX( jtb xxcso_jtf_tasks_b_n18 )
             */
             jtb.attribute11            attribute11,            -- �L���K��敪
             jtb.task_id                task_id,                -- TASK ID
             jtb.object_version_number  object_version_number   -- �I�u�W�F�N�g���@�[�W����No
      FROM   jtf_tasks_b jtb
      WHERE  jtb.owner_id                      = in_resource_id
      AND    jtb.source_object_id              = in_party_id
      AND    jtb.source_object_type_code       = cv_source_party
      AND    TRUNC(jtb.actual_end_date)        = ld_visit_date
      AND    jtb.attribute12     IN (cv_registration_division_3,
                                     cv_registration_division_4,
                                     cv_registration_division_5)
      AND    jtb.deleted_flag                  = cd_del_flg_n
      AND    jtb.owner_type_code               = cv_own_typ
      AND    (
             jtb.attribute11                  != cv_effective_visit_1
             OR     (jtb.attribute11           = cv_effective_visit_1
                     AND
                     jtb.task_id              != it_task_id
                    )
             )
      FOR UPDATE NOWAIT;
/* 2011/03/28 Ver1.5 ADD End   */
--
    -- ================
    -- ���[�U�[��`��O
    -- ================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode :=xxccp_common_pkg.set_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    --1.�����`�F�b�N
    --==============================================================
    --==================================
    --1-1.���\�[�XID�̕K�{�`�F�b�N
    --==================================
    IF ( in_resource_id IS NULL ) THEN
      lt_msg_num := ct_msg_app_xxcos1_13568;
      RAISE global_indispensability_expt;
    END IF;
    --==================================
    --1-2.�p�[�e�BID�̕K�{�`�F�b�N
    --==================================
    IF ( in_party_id IS NULL ) THEN
      lt_msg_num := ct_msg_app_xxcos1_13569;
      RAISE global_indispensability_expt;
    END IF;
    --==================================
    --1-3.�p�[�e�B���̂̕K�{�`�F�b�N
    --==================================
    IF ( iv_party_name IS NULL ) THEN
      lt_msg_num := ct_msg_app_xxcos1_13570;
      RAISE global_indispensability_expt;
    END IF;
    --==================================
    --1-4.�K������̕K�{�`�F�b�N
    --==================================
    IF ( id_visit_date IS NULL ) THEN
      lt_msg_num := ct_msg_app_xxcos1_13571;
      RAISE global_indispensability_expt;
    END IF;
    --==================================
    --1-5.������z�̕K�{�`�F�b�N
    --==================================
    IF ( in_sales_amount IS NULL ) THEN
      lt_msg_num := ct_msg_app_xxcos1_13572;
      RAISE global_indispensability_expt;
    END IF;
    --==================================
    --1-6.�o�^�敪�̕K�{�`�F�b�N
    --==================================
    IF ( iv_entry_class IS NULL ) THEN
      lt_msg_num := ct_msg_app_xxcos1_13573;
      RAISE global_indispensability_expt;
    END IF;
    --==================================
    --1-7.�o�^���\�[�X�ԍ��̕K�{�`�F�b�N
    --==================================
--****************************** 2009/05/18 1.3 T.Kitajima MOD START ******************************--
--    IF ( iv_source_no IS NULL ) THEN
    IF ( iv_source_no IS NULL ) AND
       ( iv_entry_class != cv_registration_division_4 )
    THEN
--****************************** 2009/05/18 1.3 T.Kitajima MOD START ******************************--
      lt_msg_num := ct_msg_app_xxcos1_13574;
      RAISE global_indispensability_expt;
    END IF;
    --==================================
    --1-8.�ڋq�X�e�[�^�X�̕K�{�`�F�b�N
    --==================================
    IF ( iv_customer_status IS NULL ) THEN
      lt_msg_num := ct_msg_app_xxcos1_13575;
      RAISE global_indispensability_expt;
    END IF;
    --==================================
    --1-9.���͋敪�̕K�{�`�F�b�N
    --==================================
    IF ( iv_input_division IS NULL ) THEN
      lt_msg_num := ct_msg_app_xxcos1_13579;
      RAISE global_indispensability_expt;
    END IF;
    --==================================
    --1-10.������z�}�C�i�X�`�F�b�N
    --==================================
    IF ( in_sales_amount < 0 ) THEN
      lt_msg_num := ct_msg_app_xxcos1_13582;
      RAISE global_indispensability_expt;
    END IF;
--
    --==================================
    --2.�o�^�敪�m�F
    --==================================
    IF ( iv_entry_class = cv_registration_division_3 ) THEN
      lv_description := cv_details_delivery;                   -- �[�i���
    ELSIF ( iv_entry_class = cv_registration_division_4 ) THEN
      lv_description := cv_details_payment;                    -- �������
    ELSIF ( iv_entry_class = cv_registration_division_5 ) THEN
      lv_description := cv_details_digestion;                  -- �������
    ELSE
      lv_key_info := iv_entry_class;
      RAISE global_registration_expt;
    END IF;
--
    --==================================
    --3.�L���K��敪�`�F�b�N
    --==================================
    lv_effective_visi := NULL;
    --�[�i���
    IF ( iv_entry_class = cv_registration_division_3 ) THEN
      --���͋敪��1,3,5�̂Ƃ�
      IF ( iv_input_division = cv_input_division_1 OR
           iv_input_division = cv_input_division_3 OR
           iv_input_division = cv_input_division_5 ) THEN
        --���z������Ƃ�
        IF ( in_sales_amount > 0 ) THEN
          lv_effective_visi := cv_effective_visit_1;               -- �L��
        --���z��0�̂Ƃ�
        ELSIF ( in_sales_amount = 0 ) THEN
          lv_effective_visi := cv_effective_visit_0;               -- �K��
        END IF;
      --���͋敪��2,4�̂Ƃ�
      ELSIF ( iv_input_division = cv_input_division_2 OR
              iv_input_division = cv_input_division_4 ) THEN
        --�������Ȃ�
        NULL;
      --���͋敪������ȊO
      ELSE
          --�G���[
          RAISE global_effective_visi_expt;
      END IF;
    END IF;
    --�W�����
    IF ( iv_entry_class = cv_registration_division_4 ) THEN
      --���͋敪��0�̂Ƃ�
      IF ( iv_input_division = cv_input_division_0 ) THEN
        lv_effective_visi := cv_effective_visit_0;               -- �K��
      ELSE
        --�G���[
        RAISE global_effective_visi_expt;
      END IF;
    END IF;
    --�������
    IF ( iv_entry_class = cv_registration_division_5 ) THEN
      --���͋敪��0�̂Ƃ�
      IF ( iv_input_division = cv_input_division_0 ) THEN
        --���z������Ƃ�
        IF ( in_sales_amount > 0 ) THEN
          lv_effective_visi := cv_effective_visit_1;               -- �L��
        END IF;
      ELSE
        --�G���[
        RAISE global_effective_visi_expt;
      END IF;
    END IF;
--
    --�L���K��敪��NULL�̂Ƃ��͉������Ȃ�
    IF ( lv_effective_visi IS NULL ) THEN
      NULL;
    ELSE
/* 2010/11/15 Ver1.4 Add Start */
      --�����p�K����̐ݒ�
      ld_visit_date := TRUNC(id_visit_date);
/* 2010/11/15 Ver1.4 Add End   */
/* 2011/03/28 Ver1.5 ADD Start */
      --�^�X�N�f�[�^�����擾
      SELECT
             /*+
               INDEX( jtb xxcso_jtf_tasks_b_n18 )
             */
             COUNT(1)
      INTO   ln_task_cnt
      FROM   jtf_tasks_b jtb
      WHERE  jtb.owner_id                      = in_resource_id
      AND    jtb.source_object_id              = in_party_id
      AND    jtb.source_object_type_code       = cv_source_party
      AND    TRUNC(jtb.actual_end_date)        = ld_visit_date
      AND    jtb.attribute12     IN (cv_registration_division_3,cv_registration_division_4,cv_registration_division_5)
      AND    jtb.deleted_flag                  = cd_del_flg_n
      AND    jtb.owner_type_code               = cv_own_typ
      ;
      --
      IF ( ln_task_cnt > 1 ) THEN
        -- �ŌÍŏI�X�V���^�X�N���擾
        SELECT jtb_t.task_id
        INTO   lv_target_task_id
        FROM   (SELECT 
                      /*+
                      INDEX( jtb1 xxcso_jtf_tasks_b_n18 )
                      */
                      jtb1.task_id                       task_id
               FROM   jtf_tasks_b jtb1
               WHERE  jtb1.owner_id                      = in_resource_id
               AND    jtb1.source_object_id              = in_party_id
               AND    jtb1.source_object_type_code       = cv_source_party
               AND    TRUNC(jtb1.actual_end_date)        = ld_visit_date
               AND    jtb1.attribute12     IN (cv_registration_division_3,
                                               cv_registration_division_4,
                                               cv_registration_division_5)
               AND    jtb1.deleted_flag                  = cd_del_flg_n
               AND    jtb1.owner_type_code               = cv_own_typ
               AND    jtb1.attribute11                   = cv_effective_visit_1
               ORDER BY jtb1.last_update_date, jtb1.task_id ASC)  jtb_t
        WHERE  ROWNUM                             = 1
        ;
        -- �^�X�N�f�[�^�폜
        FOR task_rec IN task_data_cur(lv_target_task_id) LOOP
          xxcso_task_common_pkg.delete_task(
             in_task_id     => task_rec.task_id                --�^�X�NID
            ,in_obj_ver_num => task_rec.object_version_number  --�I�u�W�F�N�g���@�[�W����No
            ,ov_errbuf      => lv_errbuf                       --�G���[�o�b�t�@�[
            ,ov_retcode     => lv_retcode                      --�G���[�R�[�h
            ,ov_errmsg      => lv_errmsg                       --�G���[���b�Z�[�W
          );
          -- �폜�`�F�b�N
          IF ( lv_retcode != cv_status_normal ) THEN
            RAISE global_api_expt;
          END IF;
        END LOOP;
        --
      END IF;
/* 2011/03/28 Ver1.5 ADD End   */
      --TASK�f�[�^�擾(�L���K��敪)
      BEGIN
/* 2010/11/15 Ver1.4 Mod Start */
--        SELECT jtb.attribute11,           -- �L���K��敪
        SELECT
               /*+
                 INDEX( jtb xxcso_jtf_tasks_b_n18 )
               */
               jtb.attribute11,           -- �L���K��敪
/* 2010/11/15 Ver1.4 Mod End   */
               jtb.task_id,               -- TASK ID
               jtb.object_version_number  -- �I�u�W�F�N�g���@�[�W����No
        INTO   lt_task_effective_visi,
               lt_task_id,
               lt_ovn
        FROM   jtf_tasks_b jtb
        WHERE  jtb.owner_id                                  = in_resource_id
        AND    jtb.source_object_id                          = in_party_id
        AND    jtb.source_object_type_code                   = cv_source_party
--****************************** 2009/11/24 1.3 S.Miyakoshi MOD START ******************************--
--        AND    jtb.actual_end_date BETWEEN TRUNC(id_visit_date,cv_trunc_format_dd) AND TRUNC(id_visit_date + 1 ,cv_trunc_format_dd)
/* 2010/11/15 Ver1.4 Mod Start */
--        AND    TRUNC(jtb.actual_end_date,cv_trunc_format_dd) = TRUNC(id_visit_date,cv_trunc_format_dd)
        AND    TRUNC(jtb.actual_end_date) = ld_visit_date
/* 2010/11/15 Ver1.4 Mod End   */
--****************************** 2009/11/24 1.3 S.Miyakoshi MOD END ********************************--
        AND    jtb.attribute12     IN (cv_registration_division_3,cv_registration_division_4,cv_registration_division_5)
        AND    jtb.deleted_flag    = cd_del_flg_n
        AND    jtb.owner_type_code = cv_own_typ
        ;
        --
        --�L���K��敪��NULL�̏ꍇ
        IF ( lt_task_effective_visi IS NULL ) THEN
          RAISE global_get_effective_visi_expt;
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
         --==================================
      --4.�L���K��敪���L���̏ꍇ
      --==================================
      IF ( lv_effective_visi = cv_effective_visit_1 ) THEN        -- IN�p�����L��
        IF ( lt_task_effective_visi = cv_effective_visit_1 ) THEN -- TASK���L��
          NULL;
        ELSIF ( lt_task_effective_visi = cv_effective_visit_0 ) THEN -- TASK���K��
          --TASK������U�폜
          xxcso_task_common_pkg.delete_task(
             in_task_id     => lt_task_id               --�^�X�NID
            ,in_obj_ver_num => lt_task_effective_visi   --�I�u�W�F�N�g���@�[�W����No
            ,ov_errbuf      => lv_errbuf                --�G���[�o�b�t�@�[
            ,ov_retcode     => lv_retcode               --�G���[�R�[�h
            ,ov_errmsg      => lv_errmsg                --�G���[���b�Z�[�W
          );
          --�폜�`�F�b�N
          IF ( lv_retcode != cv_status_normal ) THEN
            RAISE global_api_expt;
          END IF;
          --TASK����o�^
          xxcso_task_common_pkg.create_task(
             in_resource_id => in_resource_id           --���\�[�XID
            ,in_party_id    => in_party_id              --�ڋq�p�[�e�BID
            ,iv_party_name  => iv_party_name            --�ڋq�p�[�e�B����
-- 2017/04/12 Ver.1.6 Y.Shoji ADD Start
            ,id_input_date  => NULL                     --�f�[�^���͓���
-- 2017/04/12 Ver.1.6 Y.Shoji ADD End
            ,id_visit_date  => id_visit_date            --�K�����
            ,iv_description => lv_description           --�ڍד��e
            ,iv_attribute1  => NULL
            ,iv_attribute2  => NULL
            ,iv_attribute3  => NULL
            ,iv_attribute4  => NULL
            ,iv_attribute5  => NULL
            ,iv_attribute6  => NULL
            ,iv_attribute7  => NULL
            ,iv_attribute8  => NULL
            ,iv_attribute9  => NULL
            ,iv_attribute10 => NULL
            ,iv_attribute11 => lv_effective_visi        --�L���K��敪
            ,iv_attribute12 => iv_entry_class           --�o�^�敪
            ,iv_attribute13 => iv_source_no             --�o�^���\�[�X�ԍ�
            ,iv_attribute14 => iv_customer_status       --�ڋq�X�e�[�^�X
            ,on_task_id     => lt_task_id               --�^�X�NID
            ,ov_errbuf      => lv_errbuf                --�G���[�o�b�t�@�[
            ,ov_retcode     => lv_retcode               --�G���[�R�[�h
            ,ov_errmsg      => lv_errmsg                --�G���[���b�Z�[�W
          );
          --�o�^�`�F�b�N
          IF ( lv_retcode != cv_status_normal ) THEN
            RAISE global_api_expt;
          END IF;
        ELSE
          --TASK����o�^
          xxcso_task_common_pkg.create_task(
             in_resource_id => in_resource_id           --���\�[�XID
            ,in_party_id    => in_party_id              --�ڋq�p�[�e�BID
            ,iv_party_name  => iv_party_name            --�ڋq�p�[�e�B����
-- 2017-04-12 Ver.1.6 Y.Shoji ADD Start
            ,id_input_date  => NULL                     --�f�[�^���͓���
-- 2017-04-12 Ver.1.6 Y.Shoji ADD End
            ,id_visit_date  => id_visit_date            --�K�����
            ,iv_description => lv_description           --�ڍד��e
            ,iv_attribute1  => NULL
            ,iv_attribute2  => NULL
            ,iv_attribute3  => NULL
            ,iv_attribute4  => NULL
            ,iv_attribute5  => NULL
            ,iv_attribute6  => NULL
            ,iv_attribute7  => NULL
            ,iv_attribute8  => NULL
            ,iv_attribute9  => NULL
            ,iv_attribute10 => NULL
            ,iv_attribute11 => lv_effective_visi        --�L���K��敪
            ,iv_attribute12 => iv_entry_class           --�o�^�敪
            ,iv_attribute13 => iv_source_no             --�o�^���\�[�X�ԍ�
            ,iv_attribute14 => iv_customer_status       --�ڋq�X�e�[�^�X
            ,on_task_id     => lt_task_id               --�^�X�NID
            ,ov_errbuf      => lv_errbuf                --�G���[�o�b�t�@�[
            ,ov_retcode     => lv_retcode               --�G���[�R�[�h
            ,ov_errmsg      => lv_errmsg                --�G���[���b�Z�[�W
          );
          --�o�^�`�F�b�N
          IF ( lv_retcode != cv_status_normal ) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
      END IF;
  --
      --==================================
      --5.�L���K��敪���K��̏ꍇ
      --==================================
      IF ( lv_effective_visi = cv_effective_visit_0 ) THEN        -- IN�p�����K��
        IF ( lt_task_effective_visi = cv_effective_visit_1 ) THEN -- TASK���L��
          NULL;
        ELSIF ( lt_task_effective_visi = cv_effective_visit_0 ) THEN -- TASK���K��
          NULL;
        ELSE
          --TASK����o�^
          xxcso_task_common_pkg.create_task(
             in_resource_id => in_resource_id           --���\�[�XID
            ,in_party_id    => in_party_id              --�ڋq�p�[�e�BID
            ,iv_party_name  => iv_party_name            --�ڋq�p�[�e�B����
-- 2017-04-12 Ver.1.6 Y.Shoji ADD Start
            ,id_input_date  => NULL                     --�f�[�^���͓���
-- 2017-04-12 Ver.1.6 Y.Shoji ADD End
            ,id_visit_date  => id_visit_date            --�K�����
            ,iv_description => lv_description           --�ڍד��e
            ,iv_attribute1  => NULL
            ,iv_attribute2  => NULL
            ,iv_attribute3  => NULL
            ,iv_attribute4  => NULL
            ,iv_attribute5  => NULL
            ,iv_attribute6  => NULL
            ,iv_attribute7  => NULL
            ,iv_attribute8  => NULL
            ,iv_attribute9  => NULL
            ,iv_attribute10 => NULL
            ,iv_attribute11 => lv_effective_visi        --�L���K��敪
            ,iv_attribute12 => iv_entry_class           --�o�^�敪
            ,iv_attribute13 => iv_source_no             --�o�^���\�[�X�ԍ�
            ,iv_attribute14 => iv_customer_status       --�ڋq�X�e�[�^�X
            ,on_task_id     => lt_task_id               --�^�X�NID
            ,ov_errbuf      => lv_errbuf                --�G���[�o�b�t�@�[
            ,ov_retcode     => lv_retcode               --�G���[�R�[�h
            ,ov_errmsg      => lv_errmsg                --�G���[���b�Z�[�W
          );
          --�o�^�`�F�b�N
          IF ( lv_retcode != cv_status_normal ) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --�K�{�G���[
    WHEN global_indispensability_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  lt_msg_num
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --�o�^�敪�w��G���[
    WHEN global_registration_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_app_xxcos1_13576,
        iv_token_name1        =>  cv_tkn_in_param,
        iv_token_value1       =>  lv_key_info
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --�L���K���ԃG���[
    WHEN global_effective_visi_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_app_xxcos1_13577,
        iv_token_name1        =>  cv_tkn_in_param1,
        iv_token_value1       =>  iv_entry_class,
        iv_token_name2        =>  cv_tkn_in_param2,
        iv_token_value2       =>  iv_input_division,
        iv_token_name3        =>  cv_tkn_in_param3,
        iv_token_value3       =>  in_sales_amount
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --�L���K��擾�G���[
    WHEN global_get_effective_visi_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_app_xxcos1_13578,
        iv_token_name1        =>  cv_tkn_in_param1,
        iv_token_value1       =>  in_resource_id,
        iv_token_name2        =>  cv_tkn_in_param2,
        iv_token_value2       =>  id_visit_date
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
/* 2011/03/28 Ver1.5 ADD Start */
    --���b�N�G���[
    WHEN record_lock_expt THEN
      IF ( task_data_cur%ISOPEN ) THEN
        CLOSE task_data_cur;
      END IF;
      -- ���b�Z�[�W�쐬
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name
       ,iv_name               =>  ct_msg_app_xxcos1_00001
       ,iv_token_name1        =>  cv_tkn_table
       ,iv_token_value1       =>  cv_table_task
      );
      --
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
/* 2011/03/28 Ver1.5 ADD End   */
---
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END task_entry;
--
END XXCOS_TASK_PKG;
/
