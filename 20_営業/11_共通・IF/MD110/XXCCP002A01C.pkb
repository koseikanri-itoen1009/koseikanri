CREATE OR REPLACE PACKAGE BODY XXCCP002A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCCP002A01C(body)
 * Description      : �I�����i�f�[�^CSV�_�E�����[�h
 * MD.070           : �I�����i�f�[�^CSV�_�E�����[�h (MD070_IPO_CCP_002_A01)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/10/18    1.0   H.Sakihama      [E_�{�ғ�_13895]�V�K�쐬
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gn_target_cnt             NUMBER;                    -- �Ώی���
  gn_normal_cnt             NUMBER;                    -- ���팏��
  gn_error_cnt              NUMBER;                    -- �G���[����
  gn_warn_cnt               NUMBER;                    -- �x������
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
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCCP002A01C';              -- �p�b�P�[�W��
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- �A�h�I���F���ʁEIF�̈�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_practice_month     IN  VARCHAR2      --   �N��
   ,ov_errbuf             OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain';                   -- �v���O������
    cv_org_code_p           CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:�݌ɑg�D�R�[�h
    -- ���b�Z�[�W�R�[�h
    cv_msg_00001            CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00005';          -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
    cv_msg_00002            CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00006';          -- �݌ɑg�DID�擾�G���[���b�Z�[�W
    cv_msg_00003            CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00011';          -- �Ɩ����t�擾�G���[���b�Z�[�W
    -- �g�[�N���R�[�h
    cv_xxcoi_sn             CONSTANT VARCHAR2(9)   := 'XXCOI';                     -- SHORT_NAME_FOR_XXCOI
    cv_protok_sn            CONSTANT VARCHAR2(20)  := 'PRO_TOK';
    cv_orgcode_sn           CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';
--
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf               VARCHAR2(5000);                                        -- �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1);                                           -- ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000);                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- ���[�J���ϐ�
    ld_process_date         DATE;                                                  -- �Ɩ����t
    ld_target_date          DATE;                                                  -- �Ώۓ��t
    ld_practice_month       DATE;                                                  -- �I���N��
    ln_organization_id      NUMBER;                                                -- �݌ɑg�DID
    lv_organization_code    VARCHAR2(30);                                          -- �݌ɑg�D�R�[�h
    -- �o�͗p����
    lv_out_data             VARCHAR2(3000);                                        -- �o�̓f�[�^
    lv_description          mtl_secondary_inventories.description%TYPE;            -- �ۊǏꏊ����
    ln_page_num             NUMBER(5);                                             -- �y�[�WNo
    ln_line_num             NUMBER(2);                                             -- �sNo
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �I�����i���R�[�h�擾
    CURSOR main_cur
    IS
      SELECT sub.practice_month   AS practice_month  -- �I���N��
            ,sub.base_code        AS base_code       -- �X�܃R�[�h
            ,sub.item_code        AS item_code       -- �i�ԃR�[�h
            ,sub.item_short_name  AS item_short_name -- ���i��
            ,sub.description      AS description     -- �ۊǏꏊ����
      FROM  (SELECT msi.description                     description               -- �ۊǏꏊ����
                   ,msi.attribute7                      base_code                 -- ���_�R�[�h(�X�܃R�[�h)
                   ,sib.sp_supplier_code                sp_supplier_code          -- ���X�d����R�[�h
                   ,sib.item_code                       item_code                 -- �i���R�[�h
                   ,SUBSTR(
                       (CASE  WHEN  TRUNC(TO_DATE(iib.attribute3, 'YYYY/MM/DD')) > TRUNC(ld_target_date)
                              THEN  iib.attribute1                                -- �Q�R�[�h(��)
                              ELSE  iib.attribute2                                -- �Q�R�[�h(�V)
                        END
                       ), 1, 3
                    )                                   gun_code                  -- �Q�R�[�h
                   ,imb.item_short_name                 item_short_name           -- ����
                   ,xirm.practice_month                 practice_month            -- �I���N��
             FROM   xxcoi_inv_reception_monthly     xirm                          -- �����݌Ɏ󕥕\
                   ,mtl_secondary_inventories       msi                           -- �ۊǏꏊ�}�X�^(INV)
                   ,mtl_system_items_b              msib                          -- Disc�i��        (INV)
                   ,ic_item_mst_b                   iib                           -- OPM�i��         (GMI)
                   ,xxcmn_item_mst_b                imb                           -- OPM�i�ڃA�h�I�� (XXCMN)
                   ,xxcmm_system_items_b            sib                           -- Disc�i�ڃA�h�I��(XXCMM)
             WHERE  xirm.organization_id        = ln_organization_id
             AND    xirm.subinventory_type      = '4'                             -- �ۊǏꏊ�敪(���X)
             AND    xirm.practice_month         = TO_CHAR(ADD_MONTHS(ld_practice_month, -1), 'YYYYMM')
             AND    xirm.inventory_kbn          = '2'                             -- �I���敪(����)
             AND    xirm.inv_result + xirm.inv_result_bad <> 0                    -- ����I��0�ȊO
             AND    xirm.subinventory_code      = msi.secondary_inventory_name
             AND    xirm.organization_id        = msi.organization_id
             AND    msi.attribute1              = '4'                             -- �ۊǏꏊ�敪(���X)
             AND    TRUNC(NVL(msi.disable_date, ld_target_date)) >= TRUNC(ld_target_date)
             AND    xirm.inventory_item_id      = msib.inventory_item_id
             AND    xirm.organization_id        = msib.organization_id
             AND    msib.segment1               = iib.item_no
             AND    iib.item_id                 = imb.item_id
             AND    imb.item_id                 = sib.item_id
             AND    TRUNC(ld_target_date) BETWEEN imb.start_date_active
                                              AND NVL(imb.end_date_active, TRUNC(ld_target_date))
           ) sub
      ORDER BY sub.base_code
              ,sub.description
              ,sub.sp_supplier_code
              ,sub.gun_code
              ,sub.item_code
      ;
    -- ���C���J�[�\�����R�[�h�^
    main_rec  main_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode    := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    --==============================================================
    -- ���̓p�����[�^�o��
    --==============================================================
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�N�� : ' || iv_practice_month
    );
--
    --==================================================
    -- �I���N���ݒ�
    --==================================================
    BEGIN
      ld_practice_month := TO_DATE(iv_practice_month, 'YYYYMM');
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf  := '�p�����[�^�u�N���v�ɂ́A���t�Ƃ��Đ������N�����w�肵�Ă��������B';
        lv_retcode := cv_status_error;    -- �ُ�:2
        RAISE global_process_expt;
    END;
--
    --==================================================
    -- �݌ɑg�D�擾
    --==================================================
    -- ���ʊ֐�(�݌ɑg�D�R�[�h�擾)���g�p���v���t�@�C�����݌ɑg�D�R�[�h���擾���܂��B
    lv_organization_code := FND_PROFILE.VALUE(cv_org_code_p);
    IF (lv_organization_code IS NULL) THEN
      -- �v���t�@�C��:�݌ɑg�D�R�[�h( &PRO_TOK )�̎擾�Ɏ��s���܂����B
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_00001
                   ,iv_token_name1  => cv_protok_sn
                   ,iv_token_value1 => cv_org_code_p
                   );
      lv_errbuf  := lv_errmsg;
      lv_retcode := cv_status_error;    -- �ُ�:2
      RAISE global_process_expt;
    END IF;
--
    -- ��L�Ŏ擾�����݌ɑg�D�R�[�h�����Ƃɋ��ʕ��i(�݌ɑg�DID�擾)���݌ɑg�DID�擾���܂��B
    ln_organization_id := xxcoi_common_pkg.get_organization_id(lv_organization_code);
    --
    IF (ln_organization_id IS NULL) THEN
      -- �݌ɑg�D�R�[�h( &ORG_CODE_TOK )�ɑ΂���݌ɑg�DID�̎擾�Ɏ��s���܂����B
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_00002
                   ,iv_token_name1  => cv_orgcode_sn
                   ,iv_token_value1 => lv_organization_code
                   );
      lv_errbuf  := lv_errmsg;
      lv_retcode := cv_status_error;    -- �ُ�:2
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- �Ώۓ��t�擾
    --==================================================
    -- �Ɩ����t�擾
    ld_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF ( ld_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_00003
                   );
      lv_errbuf  := lv_errmsg;
      lv_retcode := cv_status_error;    -- �ُ�:2
      RAISE global_process_expt;
    END IF;
--
    -- �Ώۓ��t����
    IF (LAST_DAY(ld_practice_month) > ld_process_date) THEN
      ld_target_date := ld_process_date;
    ELSE
      ld_target_date := LAST_DAY(ld_practice_month);
    END IF;
--
    --==================================================
    -- ���̓p�����[�^�`�F�b�N
    --==================================================
    IF (TO_CHAR(ld_practice_month, 'YYYYMM') > TO_CHAR(ld_process_date, 'YYYYMM')) THEN
      lv_errbuf  := '�p�����[�^�u�N���v�ɖ������͐ݒ�ł��܂���B';
      lv_retcode := cv_status_error;    -- �ُ�:2
      RAISE global_process_expt;
    END IF;
--
    --==================================================
    -- �w�b�_���쐬
    --==================================================
    lv_out_data :=
              '"' || '�I���N��'           || '"' -- �I���N��
    || ',' || '"' || '�X�܃R�[�h'         || '"' -- �X�܃R�[�h
    || ',' || '"' || '�y�[�WNo'           || '"' -- �y�[�WNo
    || ',' || '"' || '�sNo'               || '"' -- �sNo
    || ',' || '"' || '�i�ԃR�[�h'         || '"' -- �i�ԃR�[�h
    || ',' || '"' || '���i��'             || '"' -- ���i��
    ;
    --==================================================
    -- �w�b�_���o��
    --==================================================
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_data
    );
    --==================================================
    -- �����l�ݒ�
    --==================================================
    lv_description := 'XXXXX';                   -- �ۊǏꏊ��
--
    --==================================================
    -- �f�[�^���擾
    --==================================================
    <<output_loop>>
    FOR main_rec IN main_cur LOOP
      -- ���͌����J�E���g
      gn_target_cnt  := gn_target_cnt + 1;
--
      --==================================================
      -- �y�[�WNo,�sNo�ݒ�
      --==================================================
      -- �ۊǏꏊ���̂��O���R�[�h�ƕς�����ꍇ
      IF ( lv_description <> main_rec.description ) THEN
        lv_description := main_rec.description;  -- �ۊǏꏊ���̂�ێ�
        ln_page_num    := 1;                     -- �y�[�WNo�̏�����
        ln_line_num    := 1;                     -- �sNo�̏�����
      ELSIF (ln_line_num >= 16) THEN
        -- �sNo���ő�l(16)�ȏ�̏ꍇ
        ln_page_num    := ln_page_num + 1;       -- �y�[�WNo�̉��Z
        ln_line_num    := 1;                     -- �sNo�̏�����
      ELSE
        ln_line_num    := ln_line_num + 1;       -- �sNo�̉��Z
      END IF;
--
      --==================================================
      -- �f�[�^����ϐ��Ɋi�[
      --==================================================
      lv_out_data :=
                '"' || iv_practice_month        || '"' -- �I���N��
      || ',' || '"' || main_rec.base_code       || '"' -- �X�܃R�[�h
      || ',' || '"' || TO_CHAR(ln_page_num)     || '"' -- �y�[�WNo
      || ',' || '"' || TO_CHAR(ln_line_num)     || '"' -- �sNo
      || ',' || '"' || main_rec.item_code       || '"' -- �i�ԃR�[�h
      || ',' || '"' || main_rec.item_short_name || '"' -- ���i��
      ;
--
      --==================================================
      -- �f�[�^���o��
      --==================================================
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_data
      );
--
      -- �o�͌����J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP output_loop;
    -- �Ώی���=0�ł���΃��b�Z�[�W�o��
    IF (gn_target_cnt = 0) THEN
     FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => CHR(10) || '�Ώۃf�[�^�͂���܂���B'
     );
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode    := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf     := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode    := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf     := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode    := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                OUT VARCHAR2      --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode               OUT VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
   ,iv_practice_month     IN  VARCHAR2      --   �N��
  )
--
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_practice_month     -- �N��
      ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCCP002A01C;
