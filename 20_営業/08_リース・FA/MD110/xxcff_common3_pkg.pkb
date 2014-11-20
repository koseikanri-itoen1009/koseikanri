create or replace PACKAGE BODY XXCFF_COMMON3_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF_COMMON3_PKG(body)
 * Description      : ���[�X�����֘A���ʊ֐�
 * MD.050           : �Ȃ�
 * Version          : 1.7
 *
 * Program List
 * --------------------      ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * --------------------      ---- ----- --------------------------------------------------
 *  insert_ob_hed             P           ���[�X�����o�^�֐�
 *  insert_ob_his             P           ���[�X��������o�^�֐�
 *  update_ob_hed             P           ���[�X�����X�V�֐�
 *  update_ob_his             P           ���[�X���������X�V�֐�
 *  create_contract_ass       P           �_��֘A����
 *  create_ob_det             P           ���[�X�������쐬
 *  create_ob_bat             P           ���[�X�������쐬�i�o�b�`�j
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-13   1.0    SCS �A���^���l   �V�K�쐬
 *  2009-02-10   1.1    SCS �A���^���l   [��QCFF_023] create_ob_bat�A��������ɂ����āANULL�l���l������悤�ɏC���B
 *  2009-02-23   1.2    SCS �A���^���l   [��QCFF_048] create_ob_bat�A�ړ�����WHO�l���Z�b�g�B
 *                                       [��QCFF_051] create_contract_ass�A���r�������Ɩ����t�ɏC���B
 *  2009-05-14   1.3    SCS ���� �r��    [��QT1_0749] create_ob_bat�A�����L���t���O�ύX���ɏ������N������悤�ɏC��
 *  2009-12-02   1.4    SCS �n�� �w      [��QE_T4_00098]
 *                                           �C���Fcreate_ob_bat
 *                                           ���̋@���[�X�����̏C�������쐬���A�X�V�O���[�X�����̏������p���悤�ɏC���B
 *  2011-12-19   1.5    SCSK ���� ����   [��QE_�{�ғ�_08123] create_contract_ass�̒��r�������p�����[�^�ŃZ�b�g����悤�ɏC���B
 *                                                            �s�v��create_contract_ass�Acreate_pay_planning���R�����g�A�E�g�B
 *  2012-10-23   1.6    SCSK ���Y ����   [��QE_�{�ғ�_10112] create_contract_ass�̃��[�X�_�񖾍ח���o�^�����ɂ����āA
 *                                                            �o�^�Ώۂł��郊�[�X�_�񖾍ח����̂��ׂĂ̗���L�q�B
 *                                                            �܂��A�X�V���R�A��v���Ԃ�NULL�œo�^����悤�ɏC���B
 *  2013-08-02   1.7    SCSK ���� �O��   [��QE_�{�ғ�_10871] ����ő��őΉ� ���[�X�_�񖾍ח���o�^�����ɐŋ��R�[�h��ǉ�
 *
 *****************************************************************************************/
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
--
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'xxcff_common3_pkg'; -- �p�b�P�[�W��
  cv_app_kbn_cff     CONSTANT VARCHAR2(5)   := 'XXCFF';
  -- �Ώۃf�[�^������܂���ł����B
  cv_msg_cff_00062   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00062';
  --
  -- �������[�h
  cv_exce_mode_ins   CONSTANT VARCHAR2(20) := 'INSERT';        -- �ǉ�
  cv_exce_mode_adj   CONSTANT VARCHAR2(20) := 'ADJUSTMENT';    -- �C��
  cv_exce_mode_chg   CONSTANT VARCHAR2(20) := 'CHANGE';        -- �ύX
  cv_exce_mode_mov   CONSTANT VARCHAR2(20) := 'MOVE';          -- �ړ�
  cv_exce_mode_dis   CONSTANT VARCHAR2(20) := 'DISSOLUTION';   -- ���L�����Z��
  cv_exce_mode_can   CONSTANT VARCHAR2(20) := 'CANCELLATION';  -- ���m��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
-- == 2011-12-19 V1.5 Deleted START ====================================================================================
--  /**********************************************************************************
--   * Function Name    : create_contract_ass
--   * Description      : �_��֘A����
--   ***********************************************************************************/
--  PROCEDURE create_contract_ass(
--    in_contract_line_id       IN        xxcff_contract_lines.contract_line_id%TYPE,       -- �_�񖾍ד���ID
--    iv_contract_status        IN        xxcff_contract_lines.contract_status%TYPE,        -- �_��X�e�[�^�X
--    in_created_by             IN        xxcff_contract_lines.created_by%TYPE,             -- �쐬��
--    id_creation_date          IN        xxcff_contract_lines.creation_date%TYPE,          -- �쐬��
--    in_last_updated_by        IN        xxcff_contract_lines.last_updated_by%TYPE,        -- �ŏI�X�V��
--    id_last_update_date       IN        xxcff_contract_lines.last_update_date%TYPE,       -- �ŏI�X�V��
--    in_last_update_login      IN        xxcff_contract_lines.last_update_login%TYPE,      -- �ŏI�X�V۸޲�
--    in_request_id             IN        xxcff_contract_lines.request_id%TYPE,             -- �v��ID
--    in_program_application_id IN        xxcff_contract_lines.program_application_id%TYPE, -- �ݶ��ĥ��۸��ѥ���ع����ID
--    in_program_id             IN        xxcff_contract_lines.program_id%TYPE,             -- �ݶ��ĥ��۸���ID
--    id_program_update_date    IN        xxcff_contract_lines.program_update_date%TYPE,    -- ��۸��эX�V��
--    ov_errbuf                OUT NOCOPY VARCHAR2,           -- �G���[�E���b�Z�[�W
--    ov_retcode               OUT NOCOPY VARCHAR2,           -- ���^�[���E�R�[�h
--    ov_errmsg                OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W
--  );
--  --
--  /**********************************************************************************
--   * Function Name    : create_pay_planning
--   * Description      : �X�^�u
--   ***********************************************************************************/
--   PROCEDURE create_pay_planning(
--      in_contract_line_id  IN        xxcff_contract_lines.contract_line_id%TYPE,  -- �_�񖾍ד���ID
--      ov_errbuf           OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W
--      ov_retcode          OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h
--      ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
--    )
--   IS
--   BEGIN
--     ov_errbuf  := NULL;
--     ov_retcode := cv_status_normal;
--     ov_errmsg  := NULL;
--   END;
-- == 2011-12-19 V1.5 Deleted END   ====================================================================================
  /**********************************************************************************
   * Function Name    : insert_ob_hed
   * Description      : ���[�X�����o�^
   ***********************************************************************************/
  PROCEDURE insert_ob_hed(
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- �������
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- �G���[�E���b�Z�[�W
    ov_retcode            OUT NOCOPY VARCHAR2,           -- ���^�[���E�R�[�h
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'insert_ob_hed';   -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
  BEGIN
  --
    -- ������
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    -- ***************************************************
    -- �V�[�P���X�̎擾
    -- ***************************************************
    --
    SELECT    xxcff_object_headers_s1.NEXTVAL
    INTO      io_object_data_rec.object_header_id
    FROM      dual
    ;
    --
    -- ***************************************************
    -- ���[�X�����o�^
    -- ***************************************************
    --
    INSERT INTO xxcff_object_headers(
       object_header_id        -- ��������ID
     , object_code             -- �����R�[�h
     , lease_class             -- ���[�X���
     , lease_type              -- ���[�X�敪
     , re_lease_times          -- �ă��[�X��
     , po_number               -- �����ԍ�
     , registration_number     -- �o�^�ԍ�
     , age_type                -- �N��
     , model                   -- �@��
     , serial_number           -- �@��
     , quantity                -- ����
     , manufacturer_name       -- ���[�J�[��
     , department_code         -- �Ǘ�����R�[�h
     , owner_company           -- �{�Ё^�H��
     , installation_address    -- ���ݒu�ꏊ
     , installation_place      -- ���ݒu��
     , chassis_number          -- �ԑ�ԍ�
     , re_lease_flag           -- �ă��[�X�v�t���O
     , cancellation_type       -- ���敪
     , cancellation_date       -- ���r����
     , dissolution_date        -- ���r���L�����Z����
     , bond_acceptance_flag    -- �؏���̃t���O
     , bond_acceptance_date    -- �؏���̓�
     , expiration_date         -- ������
     , object_status           -- �����X�e�[�^�X
     , active_flag             -- �����L���t���O
     , info_sys_if_date        -- ���[�X�Ǘ����A�g��
     , generation_date         -- ������
     , customer_code           -- �ڋq�R�[�h
     , created_by              -- �쐬��
     , creation_date           -- �쐬��
     , last_updated_by         -- �ŏI�X�V��
     , last_update_date        -- �ŏI�X�V��
     , last_update_login       -- �ŏI�X�V۸޲�
     , request_id              -- �v��ID
     , program_application_id  -- �ݶ��ĥ��۸��ѥ���ع����ID
     , program_id              -- �ݶ��ĥ��۸���ID
     , program_update_date     -- ��۸��эX�V��
    )
    VALUES(
       io_object_data_rec.object_header_id        -- ��������ID
     , io_object_data_rec.object_code             -- �����R�[�h
     , io_object_data_rec.lease_class             -- ���[�X���
     , io_object_data_rec.lease_type              -- ���[�X�敪
     , io_object_data_rec.re_lease_times          -- �ă��[�X��
     , io_object_data_rec.po_number               -- �����ԍ�
     , io_object_data_rec.registration_number     -- �o�^�ԍ�
     , io_object_data_rec.age_type                -- �N��
     , io_object_data_rec.model                   -- �@��
     , io_object_data_rec.serial_number           -- �@��
     , io_object_data_rec.quantity                -- ����
     , io_object_data_rec.manufacturer_name       -- ���[�J�[��
     , io_object_data_rec.department_code         -- �Ǘ�����R�[�h
     , io_object_data_rec.owner_company           -- �{�Ё^�H��
     , io_object_data_rec.installation_address    -- ���ݒu�ꏊ
     , io_object_data_rec.installation_place      -- ���ݒu��
     , io_object_data_rec.chassis_number          -- �ԑ�ԍ�
     , io_object_data_rec.re_lease_flag           -- �ă��[�X�v�t���O
     , io_object_data_rec.cancellation_type       -- ���敪
     , io_object_data_rec.cancellation_date       -- ���r����
     , io_object_data_rec.dissolution_date        -- ���r���L�����Z����
     , io_object_data_rec.bond_acceptance_flag    -- �؏���̃t���O
     , io_object_data_rec.bond_acceptance_date    -- �؏���̓�
     , io_object_data_rec.expiration_date         -- ������
     , io_object_data_rec.object_status           -- �����X�e�[�^�X
     , io_object_data_rec.active_flag             -- �����L���t���O
     , io_object_data_rec.info_sys_if_date        -- ���[�X�Ǘ����A�g��
     , io_object_data_rec.generation_date         -- ������
     , io_object_data_rec.customer_code           -- �ڋq�R�[�h
     , io_object_data_rec.created_by              -- �쐬��
     , io_object_data_rec.creation_date           -- �쐬��
     , io_object_data_rec.last_updated_by         -- �ŏI�X�V��
     , io_object_data_rec.last_update_date        -- �ŏI�X�V��
     , io_object_data_rec.last_update_login       -- �ŏI�X�V۸޲�
     , io_object_data_rec.request_id              -- �v��ID
     , io_object_data_rec.program_application_id  -- �ݶ��ĥ��۸��ѥ���ع����ID
     , io_object_data_rec.program_id              -- �ݶ��ĥ��۸���ID
     , io_object_data_rec.program_update_date     -- ��۸��эX�V��
    )
    ;
  --
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--###################################  �Œ蕔 END   #########################################
--
  END insert_ob_hed;
--
  /**********************************************************************************
   * Function Name    : insert_ob_his
   * Description      : ���[�X��������o�^
   ***********************************************************************************/
  PROCEDURE insert_ob_his(
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- �������
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- �G���[�E���b�Z�[�W
    ov_retcode            OUT NOCOPY VARCHAR2,           -- ���^�[���E�R�[�h
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'insert_ob_his';   -- �v���O������
    --
    cv_if_flag_no_send CONSTANT xxcff_object_histories.accounting_if_flag%TYPE := '1';  -- ��vIF�t���O(�����M)
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    ln_history_num  PLS_INTEGER;  -- �ύX����NO
    --
  BEGIN
  --
    -- ������
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    -- ***************************************************
    -- �V�[�P���X�̎擾
    -- ***************************************************
    --
    SELECT    xxcff_object_histories_s1.NEXTVAL
    INTO      ln_history_num
    FROM      dual
    ;
    --
    -- ***************************************************
    -- ���[�X��������o�^
    -- ***************************************************
    --
    INSERT INTO xxcff_object_histories(
       object_header_id         -- ��������ID
     , history_num              -- �ύX����NO
     , object_code              -- �����R�[�h
     , lease_class              -- ���[�X���
     , lease_type               -- ���[�X�敪
     , re_lease_times           -- �ă��[�X��
     , po_number                -- �����ԍ�
     , registration_number      -- �o�^�ԍ�
     , age_type                 -- �N��
     , model                    -- �@��
     , serial_number            -- �@��
     , quantity                 -- ����
     , manufacturer_name        -- ���[�J�[��
     , department_code          -- �Ǘ�����R�[�h
     , owner_company            -- �{�Ё^�H��
     , installation_address     -- ���ݒu�ꏊ
     , installation_place       -- ���ݒu��
     , chassis_number           -- �ԑ�ԍ�
     , re_lease_flag            -- �ă��[�X�v�t���O
     , cancellation_type        -- ���敪
     , cancellation_date        -- ���r����
     , dissolution_date         -- ���r���L�����Z����
     , bond_acceptance_flag     -- �؏���̃t���O
     , bond_acceptance_date     -- �؏���̓�
     , expiration_date          -- ������
     , object_status            -- �����X�e�[�^�X
     , active_flag              -- �����L���t���O
     , info_sys_if_date         -- ���[�X�Ǘ����A�g��
     , generation_date          -- ������
     , customer_code            -- �ڋq�R�[�h
     , accounting_date          -- �v���
     , accounting_if_flag       -- ��v�h�e�t���O
     , m_owner_company          -- �ړ����{�Ё^�H��
     , m_department_code        -- �ړ����Ǘ�����
     , m_installation_address   -- �ړ������ݒu�ꏊ
     , m_installation_place     -- �ړ������ݒu��
     , m_registration_number    -- �ړ����o�^�ԍ�
     , description              -- �E�v
     , created_by               -- �쐬��
     , creation_date            -- �쐬��
     , last_updated_by          -- �ŏI�X�V��
     , last_update_date         -- �ŏI�X�V��
     , last_update_login        -- �ŏI�X�V۸޲�
     , request_id               -- �v��ID
     , program_application_id   -- �ݶ��ĥ��۸��ѥ���ع����ID
     , program_id               -- �ݶ��ĥ��۸���ID
     , program_update_date      -- ��۸��эX�V��
    )
    VALUES(
       io_object_data_rec.object_header_id        -- ��������ID
     , ln_history_num                             -- �ύX����NO
     , io_object_data_rec.object_code             -- �����R�[�h
     , io_object_data_rec.lease_class             -- ���[�X���
     , io_object_data_rec.lease_type              -- ���[�X�敪
     , io_object_data_rec.re_lease_times          -- �ă��[�X��
     , io_object_data_rec.po_number               -- �����ԍ�
     , io_object_data_rec.registration_number     -- �o�^�ԍ�
     , io_object_data_rec.age_type                -- �N��
     , io_object_data_rec.model                   -- �@��
     , io_object_data_rec.serial_number           -- �@��
     , io_object_data_rec.quantity                -- ����
     , io_object_data_rec.manufacturer_name       -- ���[�J�[��
     , io_object_data_rec.department_code         -- �Ǘ�����R�[�h
     , io_object_data_rec.owner_company           -- �{�Ё^�H��
     , io_object_data_rec.installation_address    -- ���ݒu�ꏊ
     , io_object_data_rec.installation_place      -- ���ݒu��
     , io_object_data_rec.chassis_number          -- �ԑ�ԍ�
     , io_object_data_rec.re_lease_flag           -- �ă��[�X�v�t���O
     , io_object_data_rec.cancellation_type       -- ���敪
     , io_object_data_rec.cancellation_date       -- ���r����
     , io_object_data_rec.dissolution_date        -- ���r���L�����Z����
     , io_object_data_rec.bond_acceptance_flag    -- �؏���̃t���O
     , io_object_data_rec.bond_acceptance_date    -- �؏���̓�
     , io_object_data_rec.expiration_date         -- ������
     , io_object_data_rec.object_status           -- �����X�e�[�^�X
     , io_object_data_rec.active_flag             -- �����L���t���O
     , io_object_data_rec.info_sys_if_date        -- ���[�X�Ǘ����A�g��
     , io_object_data_rec.generation_date         -- ������
     , io_object_data_rec.customer_code           -- �ڋq�R�[�h
     , xxccp_common_pkg2.get_process_date         -- �v���
     , cv_if_flag_no_send                         -- ��v�h�e�t���O(�����M)
     , io_object_data_rec.m_owner_company         -- �ړ����{�Ё^�H��
     , io_object_data_rec.m_department_code       -- �ړ����Ǘ�����
     , io_object_data_rec.m_installation_address  -- �ړ������ݒu�ꏊ
     , io_object_data_rec.m_installation_place    -- �ړ������ݒu��
     , io_object_data_rec.m_registration_number   -- �ړ����o�^�ԍ�
     , io_object_data_rec.description             -- �E�v
     , io_object_data_rec.created_by              -- �쐬��
     , io_object_data_rec.creation_date           -- �쐬��
     , io_object_data_rec.last_updated_by         -- �ŏI�X�V��
     , io_object_data_rec.last_update_date        -- �ŏI�X�V��
     , io_object_data_rec.last_update_login       -- �ŏI�X�V۸޲�
     , io_object_data_rec.request_id              -- �v��ID
     , io_object_data_rec.program_application_id  -- �ݶ��ĥ��۸��ѥ���ع����ID
     , io_object_data_rec.program_id              -- �ݶ��ĥ��۸���ID
     , io_object_data_rec.program_update_date     -- ��۸��эX�V��
    )
    ;
  --
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--###################################  �Œ蕔 END   #########################################
--
  END insert_ob_his;
--
  /**********************************************************************************
   * Function Name    : update_ob_hed
   * Description      : ���[�X�����X�V
   ***********************************************************************************/
  PROCEDURE update_ob_hed(
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- �������
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- �G���[�E���b�Z�[�W
    ov_retcode            OUT NOCOPY VARCHAR2,           -- ���^�[���E�R�[�h
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'update_ob_hed';   -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    lv_info         VARCHAR2(5000);  -- �G���[���e
    --
  --
  BEGIN
  --
    -- ������
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    lv_info    := NULL;
    --
    -- ***************************************************
    -- �ΏۃX�e�[�^�X�擾
    -- ***************************************************
    --
    -- �����X�e�[�^�X���n����ĂȂ��Ƃ��́A����̃X�e�[�^�X���擾
    IF ( io_object_data_rec.object_status IS NULL ) THEN
    --
      SELECT    xoh.object_status  AS object_status
      INTO      io_object_data_rec.object_status
      FROM      xxcff_object_headers  xoh  -- ���[�X�����e�[�u��
      WHERE     xoh.object_header_id = io_object_data_rec.object_header_id  -- ��������ID
      ;
    --
    END IF;
    --
    -- ***************************************************
    -- ���[�X�����X�V
    -- ***************************************************
    --
    UPDATE xxcff_object_headers  xoh  -- ���[�X�����e�[�u��
    SET    xoh.lease_class            = io_object_data_rec.lease_class             -- ���[�X���
         , xoh.po_number              = io_object_data_rec.po_number               -- �����ԍ�
         , xoh.registration_number    = io_object_data_rec.registration_number     -- �o�^�ԍ�
         , xoh.age_type               = io_object_data_rec.age_type                -- �N��
         , xoh.model                  = io_object_data_rec.model                   -- �@��
         , xoh.serial_number          = io_object_data_rec.serial_number           -- �@��
         , xoh.quantity               = io_object_data_rec.quantity                -- ����
         , xoh.manufacturer_name      = io_object_data_rec.manufacturer_name       -- ���[�J�[��
         , xoh.department_code        = io_object_data_rec.department_code         -- �Ǘ�����R�[�h
         , xoh.owner_company          = io_object_data_rec.owner_company           -- �{�Ё^�H��
         , xoh.installation_address   = io_object_data_rec.installation_address    -- ���ݒu�ꏊ
         , xoh.installation_place     = io_object_data_rec.installation_place      -- ���ݒu��
         , xoh.chassis_number         = io_object_data_rec.chassis_number          -- �ԑ�ԍ�
         , xoh.re_lease_flag          = io_object_data_rec.re_lease_flag           -- �ă��[�X�v�t���O
         , xoh.cancellation_type      = io_object_data_rec.cancellation_type       -- ���敪
         , xoh.cancellation_date      = io_object_data_rec.cancellation_date       -- ���r����
         , xoh.dissolution_date       = io_object_data_rec.dissolution_date        -- ���r���L�����Z����
         , xoh.bond_acceptance_flag   = io_object_data_rec.bond_acceptance_flag    -- �؏���̃t���O
         , xoh.bond_acceptance_date   = io_object_data_rec.bond_acceptance_date    -- �؏���̓�
         , xoh.object_status          = io_object_data_rec.object_status           -- �����X�e�[�^�X
         , xoh.active_flag            = io_object_data_rec.active_flag             -- �����L���t���O
         , xoh.generation_date        = io_object_data_rec.generation_date         -- ������
         , xoh.customer_code          = io_object_data_rec.customer_code           -- �ڋq�R�[�h
         , xoh.last_updated_by        = io_object_data_rec.last_updated_by         -- �ŏI�X�V��
         , xoh.last_update_date       = io_object_data_rec.last_update_date        -- �ŏI�X�V��
         , xoh.last_update_login      = io_object_data_rec.last_update_login       -- �ŏI�X�V۸޲�
         , xoh.request_id             = io_object_data_rec.request_id              -- �v��ID
         , xoh.program_application_id = io_object_data_rec.program_application_id  -- �ݶ��ĥ��۸��ѥ���ع����ID
         , xoh.program_id             = io_object_data_rec.program_id              -- �ݶ��ĥ��۸���ID
         , xoh.program_update_date    = io_object_data_rec.program_update_date     -- ��۸��эX�V��
    WHERE  xoh.object_header_id = io_object_data_rec.object_header_id  -- ��������ID
    ;
    --
    -- �X�V�Ώۂ��Ȃ�������
    IF ( SQL%ROWCOUNT = 0 ) THEN
      lv_info := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_kbn_cff
                  , iv_name         => cv_msg_cff_00062
                 );
      lv_errbuf  := lv_info;
      lv_errmsg  := lv_info;
      lv_retcode := cv_status_error;
      --
      RAISE global_process_expt;
      --
    END IF;
  --
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--###################################  �Œ蕔 END   #########################################
--
  END update_ob_hed;
  --
  /**********************************************************************************
   * Function Name    : update_ob_his
   * Description      : ���[�X���������X�V�֐�
   ***********************************************************************************/
  PROCEDURE update_ob_his(
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- �������
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- �G���[�E���b�Z�[�W
    ov_retcode            OUT NOCOPY VARCHAR2,           -- ���^�[���E�R�[�h
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'update_ob_his';   -- �v���O������
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    lv_info         VARCHAR2(5000);  -- �G���[���e
    --
    ln_history_num  PLS_INTEGER;  -- �ύX����NO
  --
  BEGIN
  --
    -- ������
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    lv_info    := NULL;
    --
    -- ***************************************************
    -- �ŐV�����̎擾
    -- ***************************************************
    SELECT    temp.history_num    AS history_num
            , NVL( io_object_data_rec.object_status
                 , temp.object_status
              )                   AS object_status
    INTO      ln_history_num
            , io_object_data_rec.object_status
    FROM     (SELECT    RANK() OVER( ORDER BY xohi.history_num DESC ) AS ranking        -- �����L���O
                      , xohi.history_num                              AS history_num    -- �ύX����NO
                      , xohi.object_status                            AS object_status  -- �����X�e�[�^�X
              FROM      xxcff_object_histories  xohi  -- ���[�X��������
              WHERE     xohi.object_header_id = io_object_data_rec.object_header_id  -- ��������ID
             )  temp
    WHERE     temp.ranking = 1
    ;
    --
    -- ***************************************************
    -- ���[�X���������X�V
    -- ***************************************************
    --
    UPDATE xxcff_object_histories  xohi  -- ���[�X���������e�[�u��
    SET    xohi.lease_class            = io_object_data_rec.lease_class             -- ���[�X���
         , xohi.po_number              = io_object_data_rec.po_number               -- �����ԍ�
         , xohi.registration_number    = io_object_data_rec.registration_number     -- �o�^�ԍ�
         , xohi.age_type               = io_object_data_rec.age_type                -- �N��
         , xohi.model                  = io_object_data_rec.model                   -- �@��
         , xohi.serial_number          = io_object_data_rec.serial_number           -- �@��
         , xohi.quantity               = io_object_data_rec.quantity                -- ����
         , xohi.manufacturer_name      = io_object_data_rec.manufacturer_name       -- ���[�J�[��
         , xohi.department_code        = io_object_data_rec.department_code         -- �Ǘ�����R�[�h
         , xohi.owner_company          = io_object_data_rec.owner_company           -- �{�Ё^�H��
         , xohi.installation_address   = io_object_data_rec.installation_address    -- ���ݒu�ꏊ
         , xohi.installation_place     = io_object_data_rec.installation_place      -- ���ݒu��
         , xohi.chassis_number         = io_object_data_rec.chassis_number          -- �ԑ�ԍ�
         , xohi.re_lease_flag          = io_object_data_rec.re_lease_flag           -- �ă��[�X�v�t���O
         , xohi.cancellation_type      = io_object_data_rec.cancellation_type       -- ���敪
         , xohi.cancellation_date      = io_object_data_rec.cancellation_date       -- ���r����
         , xohi.dissolution_date       = io_object_data_rec.dissolution_date        -- ���r���L�����Z����
         , xohi.bond_acceptance_flag   = io_object_data_rec.bond_acceptance_flag    -- �؏���̃t���O
         , xohi.bond_acceptance_date   = io_object_data_rec.bond_acceptance_date    -- �؏���̓�
         , xohi.object_status          = io_object_data_rec.object_status           -- �����X�e�[�^�X
         , xohi.active_flag            = io_object_data_rec.active_flag             -- �����L���t���O
         , xohi.generation_date        = io_object_data_rec.generation_date         -- ������
         , xohi.customer_code          = io_object_data_rec.customer_code           -- �ڋq�R�[�h
         , xohi.m_owner_company        = io_object_data_rec.m_owner_company         -- �ړ����{�Ё^�H��
         , xohi.m_department_code      = io_object_data_rec.m_department_code       -- �ړ����Ǘ�����
         , xohi.m_installation_address = io_object_data_rec.m_installation_address  -- �ړ������ݒu�ꏊ
         , xohi.m_installation_place   = io_object_data_rec.m_installation_place    -- �ړ������ݒu��
         , xohi.m_registration_number  = io_object_data_rec.m_registration_number   -- �ړ����o�^�ԍ�
         , xohi.description            = io_object_data_rec.description             -- �E�v
         , xohi.last_updated_by        = io_object_data_rec.last_updated_by         -- �ŏI�X�V��
         , xohi.last_update_date       = io_object_data_rec.last_update_date        -- �ŏI�X�V��
         , xohi.last_update_login      = io_object_data_rec.last_update_login       -- �ŏI�X�V۸޲�
         , xohi.request_id             = io_object_data_rec.request_id              -- �v��ID
         , xohi.program_application_id = io_object_data_rec.program_application_id  -- �ݶ��ĥ��۸��ѥ���ع����ID
         , xohi.program_id             = io_object_data_rec.program_id              -- �ݶ��ĥ��۸���ID
         , xohi.program_update_date    = io_object_data_rec.program_update_date     -- ��۸��эX�V��
    WHERE  xohi.object_header_id = io_object_data_rec.object_header_id  -- ��������ID
    AND    xohi.history_num      = ln_history_num  -- �ύX����NO
    ;
    --
    -- �X�V�Ώۂ��Ȃ�������
    IF ( SQL%ROWCOUNT = 0 ) THEN
      lv_info := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_kbn_cff
                  , iv_name         => cv_msg_cff_00062
                 );
      lv_errbuf  := lv_info;
      lv_errmsg  := lv_info;
      lv_retcode := cv_status_error;
      --
      RAISE global_process_expt;
      --
    END IF;
  --
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--###################################  �Œ蕔 END   #########################################
--
  END update_ob_his;
--
  /**********************************************************************************
   * Function Name    : create_contract_ass
   * Description      : �_��֘A����
   ***********************************************************************************/
  PROCEDURE create_contract_ass(
    in_contract_line_id       IN        xxcff_contract_lines.contract_line_id%TYPE,       -- �_�񖾍ד���ID
    iv_contract_status        IN        xxcff_contract_lines.contract_status%TYPE,        -- �_��X�e�[�^�X
-- == 2011-12-19 V1.5 Added START ======================================================================================
    id_cancellation_date      IN        xxcff_contract_lines.cancellation_date%TYPE,      -- ���r����
-- == 2011-12-19 V1.5 Added END   ======================================================================================
    in_created_by             IN        xxcff_contract_lines.created_by%TYPE,             -- �쐬��
    id_creation_date          IN        xxcff_contract_lines.creation_date%TYPE,          -- �쐬��
    in_last_updated_by        IN        xxcff_contract_lines.last_updated_by%TYPE,        -- �ŏI�X�V��
    id_last_update_date       IN        xxcff_contract_lines.last_update_date%TYPE,       -- �ŏI�X�V��
    in_last_update_login      IN        xxcff_contract_lines.last_update_login%TYPE,      -- �ŏI�X�V۸޲�
    in_request_id             IN        xxcff_contract_lines.request_id%TYPE,             -- �v��ID
    in_program_application_id IN        xxcff_contract_lines.program_application_id%TYPE, -- �ݶ��ĥ��۸��ѥ���ع����ID
    in_program_id             IN        xxcff_contract_lines.program_id%TYPE,             -- �ݶ��ĥ��۸���ID
    id_program_update_date    IN        xxcff_contract_lines.program_update_date%TYPE,    -- ��۸��эX�V��
    ov_errbuf                OUT NOCOPY VARCHAR2,           -- �G���[�E���b�Z�[�W
    ov_retcode               OUT NOCOPY VARCHAR2,           -- ���^�[���E�R�[�h
    ov_errmsg                OUT NOCOPY VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'create_contract_ass';   -- �v���O������
    --
    cv_if_flag_no_send CONSTANT xxcff_object_histories.accounting_if_flag%TYPE := '1';  -- ��vIF�t���O(�����M)
    -- �����敪(���r���)
    cv_shori_type3     CONSTANT VARCHAR2(1) := '3';  -- '���r���'
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    ln_history_num  PLS_INTEGER;  -- �ύX����NO
    --
  BEGIN
  --
    -- ������
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    -- ***************************************************
    -- ���[�X�_�񖾍׍X�V
    -- ***************************************************
    UPDATE    xxcff_contract_lines  xcl  -- ���[�X�_�񖾍�
    SET       xcl.contract_status        = iv_contract_status                  -- �_��X�e�[�^�X
-- == 2011-12-19 V1.5 Modified START ===================================================================================
--            , xcl.cancellation_date      = xxccp_common_pkg2.get_process_date  -- ���r����
            , xcl.cancellation_date      = id_cancellation_date                -- ���r����
-- == 2011-12-19 V1.5 Modified END   ===================================================================================
            , xcl.last_updated_by        = in_last_updated_by                  -- �ŏI�X�V��
            , xcl.last_update_date       = id_last_update_date                 -- �ŏI�X�V��
            , xcl.last_update_login      = in_last_update_login                -- �ŏI�X�V۸޲�
            , xcl.request_id             = in_request_id                       -- �v��ID
            , xcl.program_application_id = in_program_application_id           -- �ݶ��ĥ��۸��ѥ���ع����ID
            , xcl.program_id             = in_program_id                       -- �ݶ��ĥ��۸���ID
            , xcl.program_update_date    = id_program_update_date              -- ��۸��эX�V��
    WHERE     xcl.contract_line_id = in_contract_line_id  -- �_�񖾍ד���ID
    ;
    --
    -- ***************************************************
    -- ���[�X�_�񖾍ח���o�^
    -- ***************************************************
    --
    INSERT INTO xxcff_contract_histories  -- �_�񖾍ח����e�[�u��
-- == 2012-10-23 V1.6 Added START ===================================================================================
            (
              contract_header_id           -- �_�����ID
            , contract_line_id             -- �_�񖾍ד���ID
            , history_num                  -- �ύX����NO
            , contract_status              -- �_��X�e�[�^�X
            , first_charge                 -- ���񌎊z���[�X��_���[�X��
            , first_tax_charge             -- �������Ŋz_���[�X��
            , first_total_charge           -- ����v_���[�X��
            , second_charge                -- 2��ڈȍ~���z���[�X��_���[�X��
            , second_tax_charge            -- 2��ڈȍ~����Ŋz_���[�X��
            , second_total_charge          -- 2��ڈȍ~�v_���[�X��
            , first_deduction              -- ���񌎊z���[�X��_�T���z
            , first_tax_deduction          -- ���񌎊z����Ŋz_�T���z
            , first_total_deduction        -- ����v_�T���z
            , second_deduction             -- 2��ڈȍ~���z���[�X��_�T���z
            , second_tax_deduction         -- 2��ڈȍ~����Ŋz_�T���z
            , second_total_deduction       -- 2��ڈȍ~�v_�T���z
            , gross_charge                 -- ���z���[�X��_���[�X��
            , gross_tax_charge             -- ���z�����_���[�X��
            , gross_total_charge           -- ���z�v_���[�X��
            , gross_deduction              -- ���z���[�X��_�T���z
            , gross_tax_deduction          -- ���z�����_�T���z
            , gross_total_deduction        -- ���z�v_�T���z
            , lease_kind                   -- ���[�X���
            , estimated_cash_price         -- ���ό����w�����z
            , present_value_discount_rate  -- ���݉��l������
            , present_value                -- ���݉��l
            , life_in_months               -- �@��ϗp�N��
            , original_cost                -- �擾���z
            , calc_interested_rate         -- �v�Z���q��
            , object_header_id             -- ��������ID
            , asset_category               -- ���Y���
            , expiration_date              -- ������
            , cancellation_date            -- ���r����
            , vd_if_date                   -- ���[�X�_����A�g��
            , info_sys_if_date             -- ���[�X�Ǘ����A�g��
            , first_installation_address   -- ����ݒu�ꏊ
            , first_installation_place     -- ����ݒu��
-- == 2013-08-02 V1.7 Added START ===================================================================================
            , tax_code                     -- �ŋ��R�[�h
-- == 2013-08-02 V1.7 Added END ===================================================================================
            , accounting_date              -- �v���
            , accounting_if_flag           -- ��v�h�e�t���O
            , description                  -- �E�v
            , update_reason                -- �X�V���R
            , period_name                  -- ��v����
            , created_by                   -- �쐬��
            , creation_date                -- �쐬��
            , last_updated_by              -- �ŏI�X�V��
            , last_update_date             -- �ŏI�X�V��
            , last_update_login            -- �ŏI�X�V���O�C��
            , request_id                   -- �v��ID
            , program_application_id       -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            , program_id                   -- �R���J�����g�E�v���O����ID
            , program_update_date          -- �v���O�����X�V��
            )
-- == 2012-10-23 V1.6 Added END ===================================================================================
    SELECT    xcl.contract_header_id              -- �_�����ID
            , xcl.contract_line_id                -- �_�񖾍ד���ID
            , xxcff_contract_histories_s1.NEXTVAL -- �ύX����NO
            , iv_contract_status                  -- �_��X�e�[�^�X
            , xcl.first_charge                    -- ���񌎊z���[�X��_���[�X��
            , xcl.first_tax_charge                -- �������Ŋz_���[�X��
            , xcl.first_total_charge              -- ����v_���[�X��
            , xcl.second_charge                   -- 2��ڈȍ~���z���[�X��_���[�X��
            , xcl.second_tax_charge               -- 2��ڈȍ~����Ŋz_���[�X��
            , xcl.second_total_charge             -- 2��ڈȍ~�v_���[�X��
            , xcl.first_deduction                 -- ���񌎊z���[�X��_�T���z
            , xcl.first_tax_deduction             -- ���񌎊z����Ŋz_�T���z
            , xcl.first_total_deduction           -- ����v_�T���z
            , xcl.second_deduction                -- 2��ڈȍ~���z���[�X��_�T���z
            , xcl.second_tax_deduction            -- 2��ڈȍ~����Ŋz_�T���z
            , xcl.second_total_deduction          -- 2��ڈȍ~�v_�T���z
            , xcl.gross_charge                    -- ���z���[�X��_���[�X��
            , xcl.gross_tax_charge                -- ���z�����_���[�X��
            , xcl.gross_total_charge              -- ���z�v_���[�X��
            , xcl.gross_deduction                 -- ���z�T���z_���[�X��
            , xcl.gross_tax_deduction             -- ���z�����_�T���z
            , xcl.gross_total_deduction           -- ���z�v_�T���z
            , xcl.lease_kind                      -- ���[�X���
            , xcl.estimated_cash_price            -- ���ό����w�����z
            , xcl.present_value_discount_rate     -- ���݉��l������
            , xcl.present_value                   -- ���݉��l
            , xcl.life_in_months                  -- �@��ϗp�N��
            , xcl.original_cost                   -- �擾���z
            , xcl.calc_interested_rate            -- �v�Z���q��
            , xcl.object_header_id                -- ��������ID
            , xcl.asset_category                  -- ���Y���
            , xcl.expiration_date                 -- ������
            , xcl.cancellation_date               -- ���r����
            , xcl.vd_if_date                      -- ���[�X�_����A�g��
            , xcl.info_sys_if_date                -- ���[�X�Ǘ����A�g
            , xcl.first_installation_address      -- ����ݒu�ꏊ
            , xcl.first_installation_place        -- ����ݒu��
-- == 2013-08-02 V1.7 Added START ===================================================================================
            , xcl.tax_code                        -- �ŋ��R�[�h
-- == 2013-08-02 V1.7 Added END ===================================================================================
            , xxccp_common_pkg2.get_process_date  -- �v���
            , cv_if_flag_no_send                  -- ��v�h�e�t���O
            , NULL                                -- �E�v
-- == 2012-10-23 V1.6 Added START ===================================================================================
            , NULL                                -- �X�V���R
            , NULL                                -- ��v����
-- == 2012-10-23 V1.6 Added END ===================================================================================
            , xcl.created_by                      -- �쐬��
            , xcl.creation_date                   -- �쐬��
            , in_last_updated_by                  -- �ŏI�X�V��
            , id_last_update_date                 -- �ŏI�X�V��
            , in_last_update_login                -- �ŏI�X�V۸޲�
            , in_request_id                       -- �v��ID
            , in_program_application_id           -- �ݶ��ĥ��۸��ѥ���ع����ID
            , in_program_id                       -- �ݶ��ĥ��۸���ID
            , id_program_update_date              -- ��۸��эX�V��
    FROM      xxcff_contract_lines  xcl  -- �_�񖾍׃e�[�u��
    WHERE     xcl.contract_line_id = in_contract_line_id  -- �_�񖾍ד���ID
    ;
    --
    -- ***************************************************
    -- FA���ʊ֐�[�x���v��쐬]
    -- ***************************************************
    xxcff003a05c.main(
      iv_shori_type       => cv_shori_type3       -- ���r���
     ,in_contract_line_id => in_contract_line_id  -- �_�񖾍ד���ID
     ,ov_errbuf           => lv_errbuf            -- �G���[�E���b�Z�[�W
     ,ov_retcode          => lv_retcode           -- ���^�[���E�R�[�h
     ,ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    -- �G���[�I����
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    --
  --
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--###################################  �Œ蕔 END   #########################################
--
  END create_contract_ass;
  --
  /**********************************************************************************
   * Function Name    : create_ob_det
   * Description      : ���[�X�������쐬
   ***********************************************************************************/
  PROCEDURE create_ob_det(
    iv_exce_mode           IN        VARCHAR2,           -- �������[�h
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- �������
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- �G���[�E���b�Z�[�W
    ov_retcode            OUT NOCOPY VARCHAR2,           -- ���^�[���E�R�[�h
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'create_ob_det';   -- �v���O������
    --
    -- �����X�e�[�^�X
    cv_ob_sts_cont_bef    CONSTANT xxcff_object_headers.object_status%TYPE   := '101';  -- ���_��
    cv_ob_sts_cont_aft    CONSTANT xxcff_object_headers.object_status%TYPE   := '102';  -- �_���
    cv_ob_sts_re_cont_bef CONSTANT xxcff_object_headers.object_status%TYPE   := '103';  -- �ă��[�X��
    cv_ob_sts_re_cont_aft CONSTANT xxcff_object_headers.object_status%TYPE   := '104';  -- �ă��[�X�_���
    cv_ob_sts_move        CONSTANT xxcff_object_headers.object_status%TYPE   := '105';  -- �ړ�
    cv_ob_sts_change      CONSTANT xxcff_object_headers.object_status%TYPE   := '106';  -- �������ύX
    cv_ob_sts_cancel_can  CONSTANT xxcff_object_headers.object_status%TYPE   := '109';  -- ���\���L�����Z��
    cv_ob_sts_cancel_own  CONSTANT xxcff_object_headers.object_status%TYPE   := '110';  -- ���m��(���ȓs��)
    cv_ob_sts_cancel_ins  CONSTANT xxcff_object_headers.object_status%TYPE   := '111';  -- ���m��(�ی��Ή�)
    -- �_��X�e�[�^�X
    cv_co_sts_cancel_own  CONSTANT xxcff_contract_lines.contract_status%TYPE := '206';  -- ���m��(���ȓs��)
    cv_co_sts_cancel_ins  CONSTANT xxcff_contract_lines.contract_status%TYPE := '207';  -- ���m��(�ی��Ή�)
    --
    -- ���[�X�敪
    cv_lease_type_ori  CONSTANT xxcff_contract_headers.lease_type%TYPE      := '1';  -- ���_��
    cv_lease_type_re   CONSTANT xxcff_contract_headers.lease_type%TYPE      := '2';  -- �ă��[�X�_��
    -- ���敪
    cv_can_type_own    CONSTANT xxcff_object_headers.cancellation_type%TYPE := '1';  -- ���ȓs��
    cv_can_type_ins    CONSTANT xxcff_object_headers.cancellation_type%TYPE := '2';  -- �ی��Ή�
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    ln_count        PLS_INTEGER;  -- �J�E���^
    ln_return       PLS_INTEGER;  -- �߂�l
    --
    lv_contract_status     xxcff_contract_lines.contract_status%TYPE := NULL;  -- �_��X�e�[�^�X
    ln_object_header_id    xxcff_object_headers.object_header_id%TYPE := NULL;  -- ��������ID
    ln_contract_header_id  xxcff_contract_headers.contract_header_id%TYPE := NULL;  -- �_�����ID
    ln_contract_line_id    xxcff_contract_lines.contract_line_id%TYPE := NULL;  -- �_�񖾍ד���ID
    --
    lv_temp_status      xxcff_object_headers.object_status%TYPE := NULL;   -- �X�e�[�^�X
    lv_temp_status_chg  xxcff_object_headers.object_status%TYPE := NULL;   -- �X�e�[�^�X
    --
  --
  BEGIN
  --
    -- ������
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    ln_count   := 0;
    --
    -- �������[�h(�ǉ�)
    IF      ( iv_exce_mode = cv_exce_mode_ins ) THEN
      --
      -- ***************************************************
      -- �������̓o�^�X�V����
      -- ***************************************************
      -- �����X�e�[�^�X���u���_��v�Ƃ��܂��B
      io_object_data_rec.object_status := cv_ob_sts_cont_bef;
      --
      -- ���[�X�����o�^
      insert_ob_hed(
        io_object_data_rec => io_object_data_rec  -- �������
       ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
       ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
       ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      -- �G���[�I����
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
      --
      -- ���[�X��������o�^
      insert_ob_his(
        io_object_data_rec => io_object_data_rec  -- �������
       ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
       ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
       ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      -- �G���[�I����
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
      --
    --
    -- �������[�h(�ǉ�)�ȊO�̂Ƃ��͌_������擾����B
    ELSE
    --
      --
      -- �������[�h(�C��)
      IF    ( iv_exce_mode = cv_exce_mode_adj ) THEN
      --
        --
        -- �ԋp�p�ɃX�e�[�^�X���i�[
        lv_temp_status := io_object_data_rec.object_status;
        -- ����p�̃X�e�[�^�X��ێ����Ă����B
        lv_temp_status_chg := NVL( io_object_data_rec.object_status
                                 , cv_ob_sts_change
                              );
        -- ***************************************************
        -- �������̓o�^�X�V����
        -- ***************************************************
        -- ���[�X�����X�V
        update_ob_hed(
          io_object_data_rec => io_object_data_rec  -- �������
         ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
         ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
         ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        -- �G���[�I����
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
        -- ����p�ɃX�e�[�^�X���i�[
        io_object_data_rec.object_status := lv_temp_status_chg;
        --
        -- ���[�X��������o�^
        insert_ob_his(
          io_object_data_rec => io_object_data_rec  -- �������
         ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
         ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
         ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        -- �����̓o�^���I������̂Ō��ɖ߂�
        io_object_data_rec.object_status := lv_temp_status;
        --
        -- �G���[�I����
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
      -- �������[�h(�ύX)
      ELSIF ( iv_exce_mode = cv_exce_mode_chg ) THEN
      --
        -- ***************************************************
        -- �������̓o�^�X�V����
        -- ***************************************************
        -- ���[�X�����X�V
        update_ob_hed(
          io_object_data_rec => io_object_data_rec  -- �������
         ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
         ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
         ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        -- �G���[�I����
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
        -- ���[�X���������X�V
        update_ob_his(
          io_object_data_rec => io_object_data_rec  -- �������
         ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
         ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
         ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        -- �G���[�I����
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
      -- �������[�h(�ړ�)
      ELSIF ( iv_exce_mode = cv_exce_mode_mov ) THEN
        --
        -- ***************************************************
        -- �������̓o�^�X�V����
        -- ***************************************************
        lv_temp_status := io_object_data_rec.object_status;
        -- ���[�X�����X�V
        update_ob_hed(
          io_object_data_rec => io_object_data_rec  -- �������
         ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
         ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
         ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        -- �G���[�I����
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
        -- ����p�ɃX�e�[�^�X���i�[
        io_object_data_rec.object_status := cv_ob_sts_move;
        --
        -- ���[�X��������o�^
        insert_ob_his(
          io_object_data_rec => io_object_data_rec  -- �������
         ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
         ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
         ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        -- �����̓o�^���I������̂Ō��ɖ߂�
        io_object_data_rec.object_status := lv_temp_status;
        --
        -- �G���[�I����
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
      -- �������[�h(���L�����Z��)
      ELSIF ( iv_exce_mode = cv_exce_mode_dis ) THEN
        --
        -- ***************************************************
        -- �������̓o�^�X�V����
        -- ***************************************************
        --
        -- �f�t�H���g�l��ݒ肵�܂��B
        io_object_data_rec.cancellation_type := NULL; -- ���敪
        --
        -- ���[�X�敪�̔��f
        -- ���_��̂Ƃ�
        IF      ( io_object_data_rec.lease_type = cv_lease_type_ori ) THEN
          -- �����X�e�[�^�X���u�_��ρv�Ƃ��܂��B
          io_object_data_rec.object_status := cv_ob_sts_cont_aft;
        -- �ă��[�X�_��̂Ƃ�
        ELSE
          -- �����̌_��󋵂��擾���܂��B
          --
          -- ������
          ln_count := 0;
          --
          SELECT    COUNT( ROWNUM )  AS cnt  -- �����擾
          INTO      ln_count
          FROM      xxcff_object_headers   xoh  -- ���[�X����
                   ,xxcff_contract_headers xch  -- ���[�X�_��
                   ,xxcff_contract_lines   xcl  -- ���[�X�_�񖾍�
          WHERE     xch.contract_header_id = xcl.contract_header_id  -- �_�����ID
          AND       xch.re_lease_times     = xoh.re_lease_times  -- �ă��[�X��
          AND       xcl.object_header_id   = xoh.object_header_id  -- ��������ID
          AND       xoh.object_code        = io_object_data_rec.object_code  -- �����R�[�h
          ;
          --
          -- �Ώۂ̌_�񂪎擾�ł��Ȃ��Ƃ�
          IF ( ln_count = 0 ) THEN
            -- �����X�e�[�^�X���u�ă��[�X�ҁv�Ƃ��܂��B
            io_object_data_rec.object_status := cv_ob_sts_re_cont_bef;
          ELSE
            -- �����X�e�[�^�X���u�ă��[�X�_��ρv�Ƃ��܂��B
            io_object_data_rec.object_status := cv_ob_sts_re_cont_aft;
          END IF;
          --
        END IF;
        --
        -- ���[�X�����X�V
        update_ob_hed(
          io_object_data_rec => io_object_data_rec  -- �������
         ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
         ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
         ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        -- �G���[�I����
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
        -- ����p�ɃX�e�[�^�X���i�[
        lv_temp_status := io_object_data_rec.object_status;
        io_object_data_rec.object_status := cv_ob_sts_cancel_can;
        --
        -- ���[�X��������o�^
        insert_ob_his(
          io_object_data_rec => io_object_data_rec  -- �������
         ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
         ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
         ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        -- �����̓o�^���I������̂Ō��ɖ߂�
        io_object_data_rec.object_status := lv_temp_status;
        --
        -- �G���[�I����
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
      -- �ړ����[�h(���m��)
      ELSIF ( iv_exce_mode = cv_exce_mode_can ) THEN
        --
        -- ***************************************************
        -- ���[�X�L�[���̎擾
        -- ***************************************************
        xxcff_common2_pkg.get_lease_key(
          iv_objectcode  => io_object_data_rec.object_code       -- �����R�[�h
         ,on_object_id   => io_object_data_rec.object_header_id  -- ��������ID
         ,on_contact_id  => ln_contract_header_id                -- �_�����ID
         ,on_line_id     => ln_contract_line_id                  -- �_�񖾍ד���ID
         ,ov_errbuf      => lv_errbuf           -- �G���[�E���b�Z�[�W
         ,ov_retcode     => lv_retcode          -- ���^�[���E�R�[�h
         ,ov_errmsg      => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        -- �G���[�I����
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
        -- ***************************************************
        -- �������̓o�^�X�V����
        -- ***************************************************
        -- ���敪�̔��f
        -- ���ȓs���̂Ƃ�
        IF      ( io_object_data_rec.cancellation_type = cv_can_type_own ) THEN
          -- �_��ƕ����̃X�e�[�^�X���u���r���(���ȓs��)�v�Ƃ��܂��B
          io_object_data_rec.object_status := cv_ob_sts_cancel_own;  -- ����
          lv_contract_status               := cv_co_sts_cancel_own;  -- �_��
        -- �ی��Ή��̂Ƃ�
        ELSIF ( io_object_data_rec.cancellation_type = cv_can_type_ins ) THEN
          -- �_��ƕ����̃X�e�[�^�X���u���r���(�ی��Ή�)�v�Ƃ��܂��B
          io_object_data_rec.object_status := cv_ob_sts_cancel_ins;  -- ����
          lv_contract_status               := cv_co_sts_cancel_ins;  -- �_��
        END IF;
-- == 2011-12-19 V1.5 Added START ======================================================================================
        -- ���r�����̐ݒ�
        IF ( io_object_data_rec.cancellation_date IS NULL ) THEN
          io_object_data_rec.cancellation_date := xxccp_common_pkg2.get_process_date;  -- ���r����
        END IF;
-- == 2011-12-19 V1.5 Added END   ======================================================================================
        --
        -- ���[�X�����X�V
        update_ob_hed(
          io_object_data_rec => io_object_data_rec  -- �������
         ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
         ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
         ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        -- �G���[�I����
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
        -- ���[�X��������o�^
        insert_ob_his(
          io_object_data_rec => io_object_data_rec  -- �������
         ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
         ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
         ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        -- �G���[�I����
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
        -- �_�񂪎��Ȃ��Ƃ��́A�ă��[�X�҂̕����Ȃ̂ŁA�_��֘A�̑���͕K�v�Ȃ��B
        IF NOT( ln_contract_line_id IS NULL ) THEN
          -- �_��֘A����
          create_contract_ass(
             in_contract_line_id       => ln_contract_line_id                       -- �_�񖾍ד���ID
           , iv_contract_status        => lv_contract_status                        -- �_��X�e�[�^�X
-- == 2011-12-19 V1.5 Added START ======================================================================================
           , id_cancellation_date      => io_object_data_rec.cancellation_date      -- ���r����
-- == 2011-12-19 V1.5 Added END   ======================================================================================
           , in_created_by             => io_object_data_rec.created_by             -- �쐬��
           , id_creation_date          => io_object_data_rec.creation_date          -- �쐬��
           , in_last_updated_by        => io_object_data_rec.last_updated_by        -- �ŏI�X�V��
           , id_last_update_date       => io_object_data_rec.last_update_date       -- �ŏI�X�V��
           , in_last_update_login      => io_object_data_rec.last_update_login      -- �ŏI�X�V۸޲�
           , in_request_id             => io_object_data_rec.request_id             -- �v��ID
           , in_program_application_id => io_object_data_rec.program_application_id -- �ݶ��ĥ��۸��ѥ���ع����ID
           , in_program_id             => io_object_data_rec.program_id             -- �ݶ��ĥ��۸���ID
           , id_program_update_date    => io_object_data_rec.program_update_date    -- ��۸��эX�V��
           , ov_errbuf                 => lv_errbuf           -- �G���[�E���b�Z�[�W
           , ov_retcode                => lv_retcode          -- ���^�[���E�R�[�h
           , ov_errmsg                 => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          --
          -- �G���[�I����
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_api_expt;
          END IF;
          --
        END IF;
        --
      END IF;
      --
    --
    END IF;
  --
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--###################################  �Œ蕔 END   #########################################
--
  END create_ob_det;
--
  /**********************************************************************************
   * Function Name    : create_ob_bat
   * Description      : ���[�X�������쐬�i�o�b�`�j
   ***********************************************************************************/
  PROCEDURE create_ob_bat(
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- �������
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- �G���[�E���b�Z�[�W
    ov_retcode            OUT NOCOPY VARCHAR2,           -- ���^�[���E�R�[�h
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'create_ob_bat';   -- �v���O������
    -- �X�e�[�^�X
    cv_ob_sts_cont_bef  CONSTANT xxcff_object_headers.object_status%TYPE := '101';  -- ���_��
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) := NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    -- ===============================
    -- �J�[�\��
    -- ===============================
    CURSOR object_data_cur(
             iv_object_header_id  xxcff_object_headers.object_header_id%TYPE
    )
    IS
      SELECT    xoh.object_header_id        AS object_header_id       -- ��������ID
              , xoh.object_code             AS object_code            -- �����R�[�h
              , xoh.lease_class             AS lease_class            -- ���[�X���
              , xoh.lease_type              AS lease_type             -- ���[�X�敪
              , xoh.re_lease_times          AS re_lease_times         -- �ă��[�X��
              , xoh.po_number               AS po_number              -- �����ԍ�
              , xoh.registration_number     AS registration_number    -- �o�^�ԍ�
              , xoh.age_type                AS age_type               -- �N��
              , xoh.model                   AS model                  -- �@��
              , xoh.serial_number           AS serial_number          -- �@��
              , xoh.quantity                AS quantity               -- ����
              , xoh.manufacturer_name       AS manufacturer_name      -- ���[�J�[��
              , xoh.department_code         AS department_code        -- �Ǘ�����R�[�h
              , xoh.owner_company           AS owner_company          -- �{�Ё^�H��
              , xoh.installation_address    AS installation_address   -- ���ݒu�ꏊ
              , xoh.installation_place      AS installation_place     -- ���ݒu��
              , xoh.chassis_number          AS chassis_number         -- �ԑ�ԍ�
              , xoh.re_lease_flag           AS re_lease_flag          -- �ă��[�X�v�t���O
              , xoh.cancellation_type       AS cancellation_type      -- ���敪
              , xoh.cancellation_date       AS cancellation_date      -- ���r����
              , xoh.dissolution_date        AS dissolution_date       -- ���r���L�����Z����
              , xoh.bond_acceptance_flag    AS bond_acceptance_flag   -- �؏���̃t���O
              , xoh.bond_acceptance_date    AS bond_acceptance_date   -- �؏���̓�
              , xoh.expiration_date         AS expiration_date        -- ������
              , xoh.object_status           AS object_status          -- �����X�e�[�^�X
              , xoh.active_flag             AS active_flag            -- �����L���t���O
              , xoh.info_sys_if_date        AS info_sys_if_date       -- ���[�X�Ǘ����A�g��
              , xoh.generation_date         AS generation_date        -- ������
              , xoh.customer_code           AS customer_code          -- �ڋq�R�[�h
              , xoh.created_by              AS created_by             -- �쐬��
              , xoh.creation_date           AS creation_date          -- �쐬��
              , xoh.last_updated_by         AS last_updated_by        -- �ŏI�X�V��
              , xoh.last_update_date        AS last_update_date       -- �ŏI�X�V��
              , xoh.last_update_login       AS last_update_login      -- �ŏI�X�V۸޲�
              , xoh.request_id              AS request_id             -- �v��ID
              , xoh.program_application_id  AS program_application_id -- �ݶ��ĥ��۸��ѥ���ع����ID
              , xoh.program_id              AS program_id             -- �ݶ��ĥ��۸���ID
              , xoh.program_update_date     AS program_update_date    -- ��۸��эX�V��
              , NULL                        AS m_owner_company        -- �ړ����{�ЍH��
              , NULL                        AS m_department_code      -- �ړ����Ǘ�����
              , NULL                        AS m_installation_address -- �ړ������ݒu�ꏊ
              , NULL                        AS m_installation_place   -- �ړ������ݒu��
              , NULL                        AS m_registration_number  -- �ړ����o�^�ԍ�
              , NULL                        AS description            -- �E�v
      FROM      xxcff_object_headers xoh  -- ���[�X����
      WHERE     xoh.object_header_id = iv_object_header_id  -- ��������ID
      ;
    --
    -- ===============================
    -- ���[�J�����R�[�h�^�ϐ�
    -- ===============================
    object_data_rec      object_data_cur%ROWTYPE;
  --
  BEGIN
  --
    -- ������
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    object_data_rec := NULL;
    --
    -- ��������ID���Z�b�g����Ă��Ȃ�������A�V�K�쐬
    IF ( io_object_data_rec.object_header_id IS NULL ) THEN
      --
      -- ***************************************************
      -- ���[�X�������쐬
      -- ***************************************************
      -- ���[�X�������쐬
      create_ob_det(
        iv_exce_mode       => cv_exce_mode_ins    -- �������[�h(�ǉ�)
       ,io_object_data_rec => io_object_data_rec  -- �������
       ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
       ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
       ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      -- �G���[�I����
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
      --
    ELSE
    --
      -- ***************************************************
      -- �������̎擾
      -- ***************************************************
      -- �J�[�\���I�[�v��
      -- �ړ�����O�̏����擾�������B�܂��A��荞�ݑΏۂ̃f�[�^��DB�̃f�[�^���r����
      -- �ύX�������������ڂ���Ń`�F�b�N�������B
      OPEN object_data_cur(
             io_object_data_rec.object_header_id  -- ��������ID
      );
      --
      -- ���R�[�h�^�Ƀf�[�^�ێ�
      FETCH object_data_cur INTO object_data_rec;
      --
      -- �J�[�\���N���[�Y
      CLOSE object_data_cur;
      --
      io_object_data_rec.m_owner_company        := object_data_rec.owner_company;         -- �{�ЍH��
      io_object_data_rec.m_department_code      := object_data_rec.department_code;       -- �Ǘ�����
      io_object_data_rec.m_installation_address := object_data_rec.installation_address;  -- ���ݒu�ꏊ
      io_object_data_rec.m_installation_place   := object_data_rec.installation_place;    -- ���ݒu��
      io_object_data_rec.m_registration_number  := object_data_rec.registration_number;   -- �o�^�ԍ�
      --
      -- �����X�e�[�^�X���u���_��v�ł������Ƃ�
      IF ( object_data_rec.object_status = cv_ob_sts_cont_bef ) THEN
        --
        -- ***************************************************
        -- ���[�X�������쐬
        -- ***************************************************
        create_ob_det(
          iv_exce_mode       => cv_exce_mode_chg    -- �������[�h(�ύX)
         ,io_object_data_rec => io_object_data_rec  -- �������
         ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
         ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
         ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        -- �G���[�I����
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
        --
      -- �����X�e�[�^�X���u���_��v�ȊO�̂Ƃ�
      ELSE
        --
        -- �ړ����ڂɕύX���������Ƃ�
        IF ( (   io_object_data_rec.owner_company        <> object_data_rec.owner_company        )  -- �{�ЍH��
          OR (   io_object_data_rec.department_code      <> object_data_rec.department_code      )  -- �Ǘ�����
          OR ( ( ( object_data_rec.installation_address    IS NOT NULL )                            -- ���ݒu�ꏊ
             AND ( io_object_data_rec.installation_address IS     NULL )
               )
            OR ( ( object_data_rec.installation_address    IS NULL     )
             AND ( io_object_data_rec.installation_address IS NOT NULL )
               )
            OR ( io_object_data_rec.installation_address <> object_data_rec.installation_address )
             )
          OR ( ( ( object_data_rec.installation_place      IS NULL     )                            -- ���ݒu��
             AND ( io_object_data_rec.installation_place   IS NOT NULL )
               )
            OR ( ( object_data_rec.installation_place      IS NOT NULL )
             AND ( io_object_data_rec.installation_place   IS     NULL )
               )
            OR ( io_object_data_rec.installation_place   <> object_data_rec.installation_place   )
             )
          OR ( ( ( object_data_rec.registration_number     IS NULL     )                            -- �o�^�ԍ�
             AND ( io_object_data_rec.registration_number  IS NOT NULL )
               )
            OR ( ( object_data_rec.registration_number     IS NOT NULL )
             AND ( io_object_data_rec.registration_number  IS     NULL )
               )
            OR ( io_object_data_rec.registration_number  <> object_data_rec.registration_number  )
             )
        ) THEN
          --
          object_data_rec.m_owner_company        := object_data_rec.owner_company;            -- �ړ����{�ЍH��
          object_data_rec.m_department_code      := object_data_rec.department_code;          -- �ړ����Ǘ�����
          object_data_rec.m_installation_address := object_data_rec.installation_address;     -- �ړ������ݒu�ꏊ
          object_data_rec.m_installation_place   := object_data_rec.installation_place;       -- �ړ������ݒu��
          object_data_rec.m_registration_number  := object_data_rec.registration_number;      -- �ړ����o�^�ԍ�
          object_data_rec.description            := io_object_data_rec.description;           -- �E�v
          object_data_rec.owner_company          := io_object_data_rec.owner_company;         -- �{�ЍH��
          object_data_rec.department_code        := io_object_data_rec.department_code;       -- �Ǘ�����
          object_data_rec.installation_address   := io_object_data_rec.installation_address;  -- ���ݒu�ꏊ
          object_data_rec.installation_place     := io_object_data_rec.installation_place;    -- ���ݒu��
          object_data_rec.registration_number    := io_object_data_rec.registration_number;   -- �o�^�ԍ�
          -- WHO�l
          object_data_rec.created_by             := io_object_data_rec.created_by;             -- �쐬��
          object_data_rec.creation_date          := io_object_data_rec.creation_date;          -- �쐬��
          object_data_rec.last_updated_by        := io_object_data_rec.last_updated_by;        -- �ŏI�X�V��
          object_data_rec.last_update_date       := io_object_data_rec.last_update_date;       -- �ŏI�X�V��
          object_data_rec.last_update_login      := io_object_data_rec.last_update_login;      -- �ŏI�X�V۸޲�
          object_data_rec.request_id             := io_object_data_rec.request_id;             -- �v��ID
          object_data_rec.program_application_id := io_object_data_rec.program_application_id; -- �ݶ��ĥ��۸��ѥ���ع����ID
          object_data_rec.program_id             := io_object_data_rec.program_id;             -- �ݶ��ĥ��۸���ID
          object_data_rec.program_update_date    := io_object_data_rec.program_update_date;    -- ��۸��эX�V��
          -- ***************************************************
          -- ���[�X�������쐬
          -- ***************************************************
          create_ob_det(
            iv_exce_mode       => cv_exce_mode_mov    -- �������[�h(�ړ�)
           ,io_object_data_rec => object_data_rec     -- �������
           ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
           ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
           ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          --
          -- �G���[�I����
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_api_expt;
          END IF;
          --
        END IF;
        --
        -- �C�����ڂɕύX���������Ƃ�
        IF ( ( ( ( io_object_data_rec.po_number         IS     NULL ) AND ( object_data_rec.po_number         IS NOT NULL ) )
            OR ( ( io_object_data_rec.po_number         IS NOT NULL ) AND ( object_data_rec.po_number         IS     NULL ) )
            OR ( ( io_object_data_rec.po_number         <> object_data_rec.po_number         ) )
             )                                                                                  -- �����ԍ�
          OR ( ( ( io_object_data_rec.age_type          IS     NULL ) AND ( object_data_rec.age_type          IS NOT NULL ) )
            OR ( ( io_object_data_rec.age_type          IS NOT NULL ) AND ( object_data_rec.age_type          IS     NULL ) )
            OR ( ( io_object_data_rec.age_type          <> object_data_rec.age_type          ) )
             )                                                                                  -- �N��
          OR ( ( ( io_object_data_rec.model             IS     NULL ) AND ( object_data_rec.model             IS NOT NULL ) )
            OR ( ( io_object_data_rec.model             IS NOT NULL ) AND ( object_data_rec.model             IS     NULL ) )
            OR ( ( io_object_data_rec.model             <> object_data_rec.model             ) )
             )                                                                                  -- �@��
          OR ( ( ( io_object_data_rec.serial_number     IS     NULL ) AND ( object_data_rec.serial_number     IS NOT NULL ) )
            OR ( ( io_object_data_rec.serial_number     IS NOT NULL ) AND ( object_data_rec.serial_number     IS     NULL ) )
            OR ( ( io_object_data_rec.serial_number     <> object_data_rec.serial_number     ) )
             )                                                                                  -- �@��
          OR ( io_object_data_rec.quantity          <> object_data_rec.quantity          )  -- ����
          OR ( ( ( io_object_data_rec.chassis_number    IS     NULL ) AND ( object_data_rec.chassis_number    IS NOT NULL ) )
            OR ( ( io_object_data_rec.chassis_number    IS NOT NULL ) AND ( object_data_rec.chassis_number    IS     NULL ) )
            OR ( ( io_object_data_rec.chassis_number    <> object_data_rec.chassis_number    ) )
             )                                                                                  -- �ԑ�ԍ�
          OR ( ( ( io_object_data_rec.manufacturer_name IS     NULL ) AND ( object_data_rec.manufacturer_name IS NOT NULL ) )
            OR ( ( io_object_data_rec.manufacturer_name IS NOT NULL ) AND ( object_data_rec.manufacturer_name IS     NULL ) )
            OR ( ( io_object_data_rec.manufacturer_name <> object_data_rec.manufacturer_name ) )
             )                                                                                  -- ���[�J�[��
          OR ( ( ( io_object_data_rec.customer_code     IS     NULL ) AND ( object_data_rec.customer_code     IS NOT NULL ) )
            OR ( ( io_object_data_rec.customer_code     IS NOT NULL ) AND ( object_data_rec.customer_code     IS     NULL ) )
            OR ( ( io_object_data_rec.customer_code     <> object_data_rec.customer_code     ) )
             )                                                                                  -- �ڋq�R�[�h
          --�yT1_0749�zADD START Matsunaka
          OR ( ( ( io_object_data_rec.active_flag       IS     NULL ) AND ( object_data_rec.active_flag       IS NOT NULL ) )
            OR ( ( io_object_data_rec.active_flag       IS NOT NULL ) AND ( object_data_rec.active_flag       IS     NULL ) )
            OR ( ( io_object_data_rec.active_flag       <> object_data_rec.active_flag     ) )
             )                                                                                  -- �����L���t���O
          --�yT1_0749�zADD END   Matsunaka
        ) THEN
          --
          io_object_data_rec.m_owner_company         := NULL;     -- �ړ����{�ЍH��
          io_object_data_rec.m_department_code       := NULL;     -- �ړ����Ǘ�����
          io_object_data_rec.m_installation_address  := NULL;     -- �ړ������ݒu�ꏊ
          io_object_data_rec.m_installation_place    := NULL;     -- �ړ������ݒu��
          io_object_data_rec.m_registration_number   := NULL;     -- �ړ����o�^�ԍ�
--
          -- E_T4_00098 2009/12/02 ADD START
          io_object_data_rec.lease_type              := object_data_rec.lease_type;     -- ���[�X�敪
          io_object_data_rec.re_lease_times          := object_data_rec.re_lease_times; -- �ă��[�X��
          io_object_data_rec.re_lease_flag           := object_data_rec.re_lease_flag;  -- �ă��[�X�v�ۃt���O
          -- E_T4_00098 2009/12/02 ADD END
--
          -- ***************************************************
          -- ���[�X�������쐬
          -- ***************************************************
          create_ob_det(
            iv_exce_mode       => cv_exce_mode_adj    -- �������[�h(�C��)
           ,io_object_data_rec => io_object_data_rec  -- �������
           ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
           ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
           ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          --
          -- �G���[�I����
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_api_expt;
          END IF;
          --
        END IF;
        --
      END IF;
      --
    END IF;
    --
  --
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( object_data_cur%ISOPEN ) THEN
        CLOSE object_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF ( object_data_cur%ISOPEN ) THEN
        CLOSE object_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( object_data_cur%ISOPEN ) THEN
        CLOSE object_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( object_data_cur%ISOPEN ) THEN
        CLOSE object_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--###################################  �Œ蕔 END   #########################################
--
  END create_ob_bat;
--
END XXCFF_COMMON3_PKG
;
/
