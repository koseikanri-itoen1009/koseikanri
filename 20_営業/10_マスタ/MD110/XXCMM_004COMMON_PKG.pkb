CREATE OR REPLACE PACKAGE BODY  XXCMM_004COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcmm_004common_pkg(spec)
 * Description            : �i�ڊ֘AAPI
 * MD.070                 : MD070_IPO_XXCMM_���ʊ֐�
 * Version                : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  put_message              ���b�Z�[�W�o��
 *  proc_opmcost_ref         OPM�������f����
 *  proc_opmitem_categ_ref   OPM�i�ڃJ�e�S���������f����
 *  del_opmitem_categ        OPM�i�ڃJ�e�S�������폜����
 *  proc_discitem_categ_ref  Disc�i�ڃJ�e�S���������f����
 *  del_discitem_categ       Disc�i�ڃJ�e�S�������폜����
 *  proc_uom_class_ref       �P�ʊ��Z���f����
 *  proc_conc_request        �R���J�����g���s(+���s�҂�)
 *  ins_opm_item             OPM�i�ړo�^����
 *  upd_opm_item             OPM�i�ڍX�V����
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/07    1.0   H.Yoshikawa      �V�K�쐬
 *  2009/01/22          K.Ito            proc_discitem_categ_ref���C:�p�����[�^�`�F�b�N�ǉ�
 *  2009/02/02          K.Ito            ���b�Z�[�W�g�[�N���ύX(ERRMSG -> ERR_MSG)
 *  2009/02/13          K.Ito            proc_conc_request:��O�����ǉ�(�R���J�����g�ҋ@�A����)
 *  2009/02/27    1.1   R.Takigawa       Disc�i�ڃJ�e�S�������폜�����Ƀp�����[�^�`�F�b�N�̒ǉ�
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--  gv_out_msg       VARCHAR2(2000);
--  gv_sep_msg       VARCHAR2(2000);
--  gv_exec_user     VARCHAR2(100);
--  gv_conc_name     VARCHAR2(30);
--  gv_conc_status   VARCHAR2(30);
--  gn_target_cnt    NUMBER;                    -- �Ώی���
--  gn_normal_cnt    NUMBER;                    -- ���팏��
--  gn_error_cnt     NUMBER;                    -- �G���[����
--  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt                EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt                    EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt             EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- ���b�Z�[�W�p�萔
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'xxcmm_004common_pkg';            -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_xxccp          CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_appl_name_xxcmm          CONSTANT VARCHAR2(5)   := 'XXCMM';
--
  -- ���b�Z�[�W
  cv_msg_xxcmm_00421          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00421';               -- ���ʊ֐��p�����[�^NULL�G���[
  cv_msg_xxcmm_00422          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00422';               -- �R���J�����g�N���G���[
  cv_msg_xxcmm_00423          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00423';               -- ����_�i�ڕs��v�G���[
  cv_msg_xxcmm_00424          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00424';               -- �f�[�^�o�^�G���[
  cv_msg_xxcmm_00425          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00425';               -- �f�[�^�X�V�G���[
  cv_msg_xxcmm_00426          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00426';               -- �R���J�����g�ҋ@�G���[
  cv_msg_xxcmm_00427          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00427';               -- �R���J�����g�����G���[
--
  -- �g�[�N��
  cv_tkn_value                CONSTANT VARCHAR2(20)  := 'VALUE';
  cv_tkn_table                CONSTANT VARCHAR2(20)  := 'TABLE';
  cv_tkn_errmsg               CONSTANT VARCHAR2(20)  := 'ERR_MSG';
  cv_tkn_req_id               CONSTANT VARCHAR2(20)  := 'REQ_ID';                         -- �v��ID
  cv_tkn_dev_phase            CONSTANT VARCHAR2(20)  := 'DEV_PHASE';                      -- DEV_PHASE
  cv_tkn_dev_status           CONSTANT VARCHAR2(20)  := 'DEV_STATUS';                     -- DEV_STATUS
--
  -- �g�[�N���l
  cv_tkn_val_ccd              CONSTANT VARCHAR2(30)  := 'OPM����';                        -- CM_CMPT_DTL
--
  -- �G���[�n���h�����O
  cv_dev_status_nomal         CONSTANT VARCHAR2(30)  := 'NORMAL';
  cv_dev_status_warn          CONSTANT VARCHAR2(30)  := 'WARNING';
  cv_dev_status_error         CONSTANT VARCHAR2(30)  := 'ERROR';
--
  cn_interval                 CONSTANT NUMBER        := 5;
--
  cn_create_cat_api_ver       CONSTANT NUMBER        := 1.0;  -- CREATE API Version Numbers
--
  -- �R���J�����gdev�t�F�[�Y
  cv_dev_phase_complete       CONSTANT VARCHAR2(30)  := 'COMPLETE';          -- '����'
  -- �R���J�����gdev�X�e�[�^�X
  cv_dev_status_normal        CONSTANT VARCHAR2(30)  := 'NORMAL';            -- '����'
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : put_message
   * Description      : ���b�Z�[�W�o��
   ***********************************************************************************/
  PROCEDURE put_message(
    iv_message_buff   IN       VARCHAR2                                        -- �o�̓��b�Z�[�W
   ,iv_output_div     IN       VARCHAR2 DEFAULT FND_FILE.OUTPUT                -- �o�͋敪
   ,ov_errbuf         OUT      VARCHAR2                                        -- �G���[�E���b�Z�[�W
   ,ov_retcode        OUT      VARCHAR2                                        -- ���^�[���E�R�[�h
   ,ov_errmsg         OUT      VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  --
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'put_message';        -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf                  VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    --
  BEGIN
    --
--##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  �Œ蕔 END   ############################
    --
    IF ( iv_output_div = FND_FILE.OUTPUT ) THEN
      -- �o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => iv_message_buff
      );
    END IF;
    --
    -- ���O
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => iv_message_buff
    );
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END put_message;
--
  /**********************************************************************************
   * Procedure Name   : proc_opmcost_ref
   * Description      : OPM�������f����
   **********************************************************************************/
  --
  PROCEDURE proc_opmcost_ref(
    i_cost_header_rec   IN         opm_cost_header_rtype
                                                      -- �����w�b�_
   ,i_cost_dist_tab     IN         opm_cost_dist_ttype
                                                      -- ��������
   ,ov_errbuf           OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'proc_opmcost_ref';    -- �v���O������
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                        VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                       VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                        VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    lv_param_name                    VARCHAR2(60);
    ln_count                         NUMBER;
    ln_ins_index                     NUMBER;
    ln_upd_index                     NUMBER;
    --
    lv_return_status                 VARCHAR2(10);   -- FND_API.G_RET_STS_SUCCESS
    ln_msg_count                     NUMBER;
    lv_msg_data                      VARCHAR2(2000);
    --
    cn_cmpntcost_id                  cm_cmpt_dtl.cmpntcost_id%TYPE;
    --
    -- �R�X�g�w�b�_
    lr_cost_header_rec               GMF_ItemCost_PUB.Header_Rec_Type;
    --
    -- �o�^�p
    -- ���Y���x��
    lt_ins_cost_tlevel_tab           GMF_ItemCost_PUB.This_Level_Dtl_Tbl_Type;
    -- ���ʃ��x���i���ݒ肵�Ȃ��j
    lt_ins_cost_llevel_tab           GMF_ItemCost_PUB.Lower_Level_Dtl_Tbl_Type;
    -- �o�^�p
    lt_ins_cost_cmpt_ids_tab         GMF_ItemCost_PUB.costcmpnt_ids_tbl_type;
    --
    -- �X�V�p
    -- ���Y���x��
    lt_upd_cost_tlevel_tab           GMF_ItemCost_PUB.This_Level_Dtl_Tbl_Type;
    -- ���ʃ��x���i���ݒ肵�Ȃ��j
    lt_upd_cost_llevel_tab           GMF_ItemCost_PUB.Lower_Level_Dtl_Tbl_Type;
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    no_param_expt                    EXCEPTION;   -- �p�����[�^�����̓G���[
    check_err_expt                   EXCEPTION;   -- ����_�i�ڕs��v�G���[
    ins_err_expt                     EXCEPTION;   -- �}���G���[
    upd_err_expt                     EXCEPTION;   -- �X�V�G���[
    --
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ϐ�������
    ln_ins_index := 0;
    ln_upd_index := 0;
--
    --------------------
    -- �w�b�_�̊i�[
    --------------------
    -- OPM�i��ID
    lr_cost_header_rec.item_id        := i_cost_header_rec.item_id;
    -- �����q�ɃR�[�h
    lr_cost_header_rec.whse_code      := cv_whse_code;
    -- �J�����_�R�[�h
    lr_cost_header_rec.calendar_code  := i_cost_header_rec.calendar_code;
    -- ����
    lr_cost_header_rec.period_code    := i_cost_header_rec.period_code;
    -- �������@
    lr_cost_header_rec.cost_mthd_code := cv_cost_mthd_code;
    -- ���s���[�U��
    lr_cost_header_rec.user_name      := FND_GLOBAL.USER_NAME;
    --
    --------------------
    -- ���ׂ̊i�[
    --------------------
    <<cost_dist_loop>>
    FOR ln_index IN 1..i_cost_dist_tab.COUNT LOOP
      --
      -- �p�����[�^�`�F�b�N
      -- �R���|�[�l���gID
      IF ( i_cost_dist_tab(ln_index).cost_cmpntcls_id IS NULL ) THEN
        -- �G���[
        lv_param_name := '�R���|�[�l���gID';
        RAISE no_param_expt;
      END IF;
      --
      -- ����ID���w�肩�ǂ���
      IF ( i_cost_dist_tab(ln_index).cmpntcost_id IS NOT NULL ) THEN
        -- �o�^�ς�����
        -- ����ID�݂̂Ŗ��Ȃ����A�O�̂��ߐ������X�V�����m�F
        SELECT      COUNT( ccmd.ROWID )
        INTO        ln_count
        FROM        cm_cmpt_dtl    ccmd
                   ,cm_cldr_dtl    ccld
        WHERE       ccld.calendar_code      = i_cost_header_rec.calendar_code             -- �J�����_�R�[�h
        AND         ccmd.item_id            = i_cost_header_rec.item_id                   -- �i��ID
        AND         ccmd.cmpntcost_id       = i_cost_dist_tab(ln_index).cmpntcost_id      -- OPM����ID
        AND         ccmd.cost_cmpntcls_id   = i_cost_dist_tab(ln_index).cost_cmpntcls_id  -- �R���|�[�l���gID
        AND         ccmd.calendar_code      = ccld.calendar_code                          -- �J�����_�R�[�h
        AND         ccmd.period_code        = ccld.period_code                            -- ���ԃR�[�h
        AND         ccmd.whse_code          = cv_whse_code                                -- �����q�ɃR�[�h
        AND         ccmd.cost_mthd_code     = cv_cost_mthd_code                           -- �������@
        AND         ccmd.cost_analysis_code = cv_cost_analysis_code;                      -- ���̓R�[�h
        --
        IF ( ln_count = 0 ) THEN
          -- �G���[
          RAISE check_err_expt;
        END IF;
        --
        cn_cmpntcost_id := i_cost_dist_tab(ln_index).cmpntcost_id;
      ELSE
        -- �g�ݍ��킹�i�J�����_�A�i�ځA�R���|�[�l���g�j�����݂��邩����
        SELECT      COUNT( ccmd.ROWID )
        INTO        ln_count
        FROM        cm_cmpt_dtl    ccmd
                   ,cm_cldr_dtl    ccld
        WHERE       ccld.calendar_code      = i_cost_header_rec.calendar_code             -- �J�����_�R�[�h
        AND         ccmd.item_id            = i_cost_header_rec.item_id                   -- �i��ID
        AND         ccmd.cost_cmpntcls_id   = i_cost_dist_tab(ln_index).cost_cmpntcls_id  -- �R���|�[�l���gID
        AND         ccmd.calendar_code      = ccld.calendar_code                          -- �J�����_�R�[�h
        AND         ccmd.period_code        = ccld.period_code                            -- ���ԃR�[�h
        AND         ccmd.whse_code          = cv_whse_code                                -- �����q�ɃR�[�h
        AND         ccmd.cost_mthd_code     = cv_cost_mthd_code                           -- �������@
        AND         ccmd.cost_analysis_code = cv_cost_analysis_code                       -- ���̓R�[�h
        AND         ROWNUM = 1;
        --
        IF ( ln_count = 1 ) THEN
        -- �g�ݍ��킹�i�J�����_�A�i�ځA�R���|�[�l���g�j�����݂��邩����
          SELECT      ccmd.cmpntcost_id
          INTO        cn_cmpntcost_id
          FROM        cm_cmpt_dtl    ccmd
                     ,cm_cldr_dtl    ccld
          WHERE       ccld.calendar_code      = i_cost_header_rec.calendar_code             -- �J�����_�R�[�h
          AND         ccmd.item_id            = i_cost_header_rec.item_id                   -- �i��ID
          AND         ccmd.cost_cmpntcls_id   = i_cost_dist_tab(ln_index).cost_cmpntcls_id  -- �R���|�[�l���gID
          AND         ccmd.calendar_code      = ccld.calendar_code                          -- �J�����_�R�[�h
          AND         ccmd.period_code        = ccld.period_code                            -- ���ԃR�[�h
          AND         ccmd.whse_code          = cv_whse_code                                -- �����q�ɃR�[�h
          AND         ccmd.cost_mthd_code     = cv_cost_mthd_code                           -- �������@
          AND         ccmd.cost_analysis_code = cv_cost_analysis_code;                      -- ���̓R�[�h
        END IF;
      END IF;
      --
      IF ( ln_count = 0 ) THEN
        -- �o�^�����C���N�������g
        ln_ins_index := ln_ins_index + 1;
        -- �o�^�p�Ɋi�[
        lt_ins_cost_tlevel_tab(ln_ins_index).cost_cmpntcls_id
                                                         := i_cost_dist_tab(ln_index).cost_cmpntcls_id;
        lt_ins_cost_tlevel_tab(ln_ins_index).cmpnt_cost
                                                         := i_cost_dist_tab(ln_index).cmpnt_cost;
        --
        -- �Œ�l
        lt_ins_cost_tlevel_tab(ln_ins_index).cost_analysis_code
                                                         := cv_cost_analysis_code;
        lt_ins_cost_tlevel_tab(ln_ins_index).burden_ind  := 0;
        lt_ins_cost_tlevel_tab(ln_ins_index).delete_mark := 0;
        --
      ELSE
        -- �X�V�����C���N�������g
        ln_upd_index := ln_upd_index + 1;
        -- �X�V�p�Ɋi�[
        lt_upd_cost_tlevel_tab(ln_upd_index).cmpntcost_id
                                                         := cn_cmpntcost_id;
        lt_upd_cost_tlevel_tab(ln_upd_index).cmpnt_cost  := i_cost_dist_tab(ln_index).cmpnt_cost;
        --
      END IF;
      --
    END LOOP cost_dist_loop;
    --
    --------------------
    -- OPM����API�R�[��
    --------------------
    IF ( ln_ins_index > 0 ) THEN
      -- GMF_ItemCost_PUB.Update_Item_Cost ���R�[�����X�V����
      GMF_ItemCost_PUB.Create_Item_Cost(
        p_api_version         => 2.0
       ,x_return_status       => lv_return_status
       ,x_msg_count           => ln_msg_count
       ,x_msg_data            => lv_msg_data
       ,p_header_rec          => lr_cost_header_rec
       ,p_this_level_dtl_tbl  => lt_ins_cost_tlevel_tab
       ,p_lower_level_dtl_Tbl => lt_ins_cost_llevel_tab
       ,x_costcmpnt_ids       => lt_ins_cost_cmpt_ids_tab
      );
      --
      IF ( lv_return_status != FND_API.G_RET_STS_SUCCESS ) THEN
        -- �G���[
        RAISE ins_err_expt;
      END IF;
    --
    END IF;
    --
    IF ( ln_upd_index > 0 ) THEN
      -- GMF_ItemCost_PUB.Update_Item_Cost ���R�[�����X�V����
      GMF_ItemCost_PUB.Update_Item_Cost(
        p_api_version         => 2.0
       ,x_return_status       => lv_return_status
       ,x_msg_count           => ln_msg_count
       ,x_msg_data            => lv_msg_data
       ,p_header_rec          => lr_cost_header_rec
       ,p_this_level_dtl_tbl  => lt_upd_cost_tlevel_tab
       ,p_lower_level_dtl_Tbl => lt_upd_cost_llevel_tab
      );
      --
      IF ( lv_return_status != FND_API.G_RET_STS_SUCCESS ) THEN
        -- �G���[
        RAISE upd_err_expt;
      END IF;
    --
    END IF;
    --
  EXCEPTION
    -- *** �p�����[�^�����͗�O�n���h�� ***
    WHEN no_param_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00421            -- ���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_value                  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_param_name                 -- �g�[�N���l1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
    -- *** ����_�i�ڕs��v��O�n���h�� ***
    WHEN check_err_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00423            -- ���b�Z�[�W
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
    -- *** OPM�����}����O�n���h�� ***
    WHEN ins_err_expt THEN
--ito->20090206 Mod
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
--                     ,iv_name         => cv_msg_xxcmm_00424            -- ���b�Z�[�W
--                     ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
--                     ,iv_token_value1 => cv_tkn_val_ccd                -- �g�[�N���l1
--                     ,iv_token_name2  => cv_tkn_errmsg                 -- �g�[�N���R�[�h1
----ito->20090106���ݒ�
--                     ,iv_token_value2 => '�G���[���b�Z�[�W�����܂�'  -- �g�[�N���l1
--                    );
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg;
      lv_errmsg  := lv_msg_data;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
    -- *** OPM�����X�V��O�n���h�� ***
    WHEN upd_err_expt THEN
--ito->20090206 Mod
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
--                     ,iv_name         => cv_msg_xxcmm_00425            -- ���b�Z�[�W
--                     ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
--                     ,iv_token_value1 => cv_tkn_val_ccd                -- �g�[�N���l1
--                     ,iv_token_name2  => cv_tkn_errmsg                 -- �g�[�N���R�[�h1
----ito->20090106���ݒ�
--                     ,iv_token_value2 => '�G���[���b�Z�[�W�����܂�'  -- �g�[�N���l1
--                    );
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg;
      lv_errmsg  := lv_msg_data;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
    --
--###########################  �Œ蕔 START #######################################################
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    --
  END proc_opmcost_ref;
--
--###########################  �Œ蕔 END   #######################################################
--
  /**********************************************************************************
   * Procedure Name   : proc_opmitem_categ_ref
   * Description      : �i�ڃJ�e�S�������o�^����
   **********************************************************************************/
  --
  PROCEDURE proc_opmitem_categ_ref(
    i_item_category_rec IN         opmitem_category_rtype
                                                      -- OPM�i�ڃJ�e�S���������R�[�h�^�C�v
   ,ov_errbuf           OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'proc_opmitem_categ_ref';    -- �v���O������
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                        VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                       VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                        VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    ln_exists_cnt                    NUMBER;
    lv_param_name                    VARCHAR2(60);
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    no_param_expt                    EXCEPTION;  -- �p�����[�^�����̓G���[
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �p�����[�^�`�F�b�N�i���ׂĕK�{�j
    -- OPM�i��ID
    IF ( i_item_category_rec.item_id IS NULL ) THEN
      lv_param_name := 'item_id';
      RAISE no_param_expt;
    END IF;
    -- �J�e�S���Z�b�gID
    IF ( i_item_category_rec.category_set_id IS NULL ) THEN
      lv_param_name := 'category_set_id';
      RAISE no_param_expt;
    END IF;
    -- �J�e�S��ID
    IF ( i_item_category_rec.category_id IS NULL ) THEN
      lv_param_name := 'category_id';
      RAISE no_param_expt;
    END IF;
    --
    --====================
    -- OPM�i�ڃJ�e�S�������o�^
    --====================
    -- ���݃`�F�b�N
    SELECT  COUNT( gic.ROWID )
    INTO    ln_exists_cnt
    FROM    gmi_item_categories gic
    WHERE   gic.item_id         = i_item_category_rec.item_id
    AND     gic.category_set_id = i_item_category_rec.category_set_id
    AND     ROWNUM              = 1;
    --
    IF ( ln_exists_cnt = 0 ) THEN
      -- OPM�i�ڃJ�e�S�������̐V�K�o�^
      INSERT INTO gmi_item_categories(
        item_id
       ,category_set_id
       ,category_id
       ,created_by
       ,creation_date
       ,last_updated_by
       ,last_update_date
       ,last_update_login)
      VALUES(
        i_item_category_rec.item_id
       ,i_item_category_rec.category_set_id
       ,i_item_category_rec.category_id
       ,cn_created_by
       ,cd_creation_date
       ,cn_last_updated_by
       ,cd_last_update_date
       ,cn_last_update_login);
    ELSE
      -- OPM�i�ڃJ�e�S�������̍X�V
      UPDATE  gmi_item_categories
      SET     category_id        = i_item_category_rec.category_id
             ,last_updated_by    = cn_last_updated_by
             ,last_update_date   = cd_last_update_date
             ,last_update_login  = cn_last_update_login
      WHERE   item_id            = i_item_category_rec.item_id
      AND     category_set_id    = i_item_category_rec.category_set_id;
    END IF;
    --
    --
  EXCEPTION
--
    -- *** �p�����[�^�����͗�O�n���h�� ***
    WHEN no_param_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00421            -- ���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_value                  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_param_name                 -- �g�[�N���l1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_opmitem_categ_ref;
--
  /**********************************************************************************
   * Procedure Name   : del_opmitem_categ
   * Description      : OPM�i�ڃJ�e�S�������폜����
   **********************************************************************************/
  --
  PROCEDURE del_opmitem_categ(
    i_item_category_rec IN         opmitem_category_rtype
                                                      -- OPM�i�ڃJ�e�S���������R�[�h�^�C�v
   ,ov_errbuf           OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'del_opmitem_categ';    -- �v���O������
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                        VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                       VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                        VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    ln_exists_cnt                    NUMBER;
    lv_param_name                    VARCHAR2(60);
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    no_param_expt                    EXCEPTION;  -- �p�����[�^�����̓G���[
    --
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �p�����[�^�`�F�b�N�i���ׂĕK�{�j
    -- OPM�i��ID
    IF ( i_item_category_rec.item_id IS NULL ) THEN
      -- �G���[
      lv_param_name := 'item_id';
      RAISE no_param_expt;
    END IF;
    -- �J�e�S���Z�b�gID
    IF ( i_item_category_rec.category_set_id IS NULL ) THEN
      -- �G���[
      lv_param_name := 'category_set_id';
      RAISE no_param_expt;
    END IF;
    -- �J�e�S��ID
    IF ( i_item_category_rec.category_id IS NULL ) THEN
      -- �G���[
      lv_param_name := 'category_id';
      RAISE no_param_expt;
    END IF;
    --
    --====================
    -- OPM�i�ڃJ�e�S�������폜
    --====================
    DELETE FROM gmi_item_categories
    WHERE  item_id         = i_item_category_rec.item_id
    AND    category_set_id = i_item_category_rec.category_set_id
    AND    category_id     = i_item_category_rec.category_id;
    --
  EXCEPTION
--
    -- *** �p�����[�^�����͗�O�n���h�� ***
    WHEN no_param_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00421            -- ���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_value                  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_param_name                 -- �g�[�N���l1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_opmitem_categ;
--
  /**********************************************************************************
   * Procedure Name   : proc_discitem_categ_ref
   * Description      : Disc�i�ڃJ�e�S�������o�^����
   **********************************************************************************/
  --
  PROCEDURE proc_discitem_categ_ref(
    i_item_category_rec IN         discitem_category_rtype
                                                      -- Disc�i�ڃJ�e�S���������R�[�h�^�C�v
   ,ov_errbuf           OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'proc_discitem_categ_ref';    -- �v���O������
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                        VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                       VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                        VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    ln_exists_cnt                    NUMBER;
    lv_param_name                    VARCHAR2(60);
    --
    -- Disc�i��ID�A�g�DID�擾�J�[�\��
    CURSOR disc_item_cur(
      pn_inventory_item_id   NUMBER )
    IS
      SELECT      msib.organization_id
      FROM        mtl_system_items_b            msib
      WHERE       msib.inventory_item_id = pn_inventory_item_id
      ORDER BY    msib.organization_id;
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    no_param_expt                    EXCEPTION;  -- �p�����[�^�����̓G���[
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �p�����[�^�`�F�b�N�i���ׂĕK�{�j
    -- Disc�i��ID
    IF ( i_item_category_rec.inventory_item_id IS NULL ) THEN
      lv_param_name := 'inventory_item_id';
      RAISE no_param_expt;
    END IF;
    -- �J�e�S���Z�b�gID
    IF ( i_item_category_rec.category_set_id IS NULL ) THEN
      lv_param_name := 'category_set_id';
      RAISE no_param_expt;
    END IF;
    -- �J�e�S��ID
    IF ( i_item_category_rec.category_id IS NULL ) THEN
      lv_param_name := 'category_id';
      RAISE no_param_expt;
    END IF;
    --
    --====================
    -- MTL����
    --====================
    <<disc_item_loop>>
    FOR l_disc_item_rec IN disc_item_cur( i_item_category_rec.inventory_item_id ) LOOP
      --
      SELECT  COUNT( mic.ROWID )
      INTO    ln_exists_cnt
      FROM    mtl_item_categories   mic
      WHERE   mic.organization_id   = l_disc_item_rec.organization_id
      AND     mic.inventory_item_id = i_item_category_rec.inventory_item_id
      AND     mic.category_set_id   = i_item_category_rec.category_set_id
      AND     ROWNUM                = 1;
      --
      IF ( ln_exists_cnt = 0 ) THEN
        -- MTL�i�ڃJ�e�S�������̐V�K�o�^
        INSERT INTO mtl_item_categories(
          organization_id
         ,inventory_item_id
         ,category_set_id
         ,category_id
         ,created_by
         ,creation_date
         ,last_updated_by
         ,last_update_date
         ,last_update_login
         ,request_id
         ,program_application_id
         ,program_id
         ,program_update_date
        ) VALUES (
          l_disc_item_rec.organization_id
         ,i_item_category_rec.inventory_item_id
         ,i_item_category_rec.category_set_id
         ,i_item_category_rec.category_id
         ,cn_created_by
         ,cd_creation_date
         ,cn_last_updated_by
         ,cd_last_update_date
         ,cn_last_update_login
         ,cn_request_id
         ,cn_program_application_id
         ,cn_program_id
         ,cd_program_update_date);
      ELSE
        -- MTL�i�ڃJ�e�S�������̍X�V
        UPDATE  mtl_item_categories
        SET     category_id            = i_item_category_rec.category_id
               ,last_updated_by        = cn_last_updated_by
               ,last_update_date       = cd_last_update_date
               ,last_update_login      = cn_last_update_login
               ,request_id             = cn_request_id
               ,program_application_id = cn_program_application_id
               ,program_id             = cn_program_id
               ,program_update_date    = cd_program_update_date
        WHERE   organization_id        = l_disc_item_rec.organization_id
        AND     inventory_item_id      = i_item_category_rec.inventory_item_id
        AND     category_set_id        = i_item_category_rec.category_set_id;
      END IF;
    END LOOP disc_item_loop;
    --
  EXCEPTION
--
    -- *** �p�����[�^�����͗�O�n���h�� ***
    WHEN no_param_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00421            -- ���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_value                  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_param_name                 -- �g�[�N���l1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_discitem_categ_ref;
--
--
  /**********************************************************************************
   * Procedure Name   : del_discitem_categ
   * Description      : Disc�i�ڃJ�e�S�������폜����
   **********************************************************************************/
  --
  PROCEDURE del_discitem_categ(
    i_item_category_rec IN         discitem_category_rtype
                                                      -- Disc�i�ڃJ�e�S���������R�[�h�^�C�v
   ,ov_errbuf           OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'del_discitem_categ';    -- �v���O������
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                        VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                       VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                        VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    ln_exists_cnt                    NUMBER;
--Takigawa->20090227 Add Start
    lv_param_name                    VARCHAR2(60);
--Takigawa->20090227 Add End
    --
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--Takigawa->20090227 Add Start
    no_param_expt                    EXCEPTION;  -- �p�����[�^�����̓G���[
--Takigawa->20090227 Add End
    --
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--Takigawa->20090227 Add Start
    -- �p�����[�^�`�F�b�N�i���ׂĕK�{�j
    -- �C���x���g��ID
    IF ( i_item_category_rec.inventory_item_id IS NULL ) THEN
      lv_param_name := 'inventory_item_id';
      RAISE no_param_expt;
    END IF;
    -- �J�e�S���Z�b�gID
    IF ( i_item_category_rec.category_set_id IS NULL ) THEN
      lv_param_name := 'category_set_id';
      RAISE no_param_expt;
    END IF;
    -- �J�e�S��ID
    IF ( i_item_category_rec.category_id IS NULL ) THEN
      lv_param_name := 'category_id';
      RAISE no_param_expt;
    END IF;
--Takigawa->20090227 Add End
    --====================
    -- MTL�����폜
    --====================
    DELETE FROM mtl_item_categories
    WHERE  inventory_item_id = i_item_category_rec.inventory_item_id
    AND    category_set_id   = i_item_category_rec.category_set_id
--Takigawa->20090227 Add Start
    AND    category_id       = i_item_category_rec.category_id;
--Takigawa->20090227 Add End
    --
  EXCEPTION
--Takigawa->20090227 Add Start
    -- *** �p�����[�^�����͗�O�n���h�� ***
    WHEN no_param_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00421            -- ���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_value                  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_param_name                 -- �g�[�N���l1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
--Takigawa->20090227 Add End
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_discitem_categ;
--
  /**********************************************************************************
   * Procedure Name   : proc_uom_class_ref
   * Description      : �P�ʊ��Z���f����
   **********************************************************************************/
  PROCEDURE proc_uom_class_ref(
    i_uom_class_conv_rec IN        uom_class_conv_rtype
                                                      -- �敪�Ԋ��Z���f�p���R�[�h�^�C�v
   ,ov_errbuf           OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'proc_uom_class_ref';    -- �v���O������
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                        VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                       VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                        VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    ln_exists_cnt                    NUMBER;
    lv_from_unit_of_measure          mtl_units_of_measure.unit_of_measure%TYPE;
    lv_from_uom_class                mtl_units_of_measure.uom_class%TYPE;
    lv_to_unit_of_measure            mtl_units_of_measure.unit_of_measure%TYPE;
    lv_to_uom_class                  mtl_units_of_measure.uom_class%TYPE;
    --
    lv_from_uom_code                 mtl_units_of_measure.uom_code%TYPE;
    lv_to_uom_code                   mtl_units_of_measure.uom_code%TYPE;
    --
    lv_param_name                    VARCHAR2(60);
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    no_param_expt                    EXCEPTION;  -- �p�����[�^�����̓G���[
    --
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �p�����[�^�`�F�b�N�i���ׂĕK�{�j
    -- Disc�i��ID
    IF ( i_uom_class_conv_rec.inventory_item_id IS NULL ) THEN
      -- �G���[
      lv_param_name := 'inventory_item_id';
      RAISE no_param_expt;
    END IF;
    -- �P�ʃR�[�h�i���Z���j
    IF ( i_uom_class_conv_rec.from_uom_code IS NULL ) THEN
      -- �G���[
      lv_param_name := 'from_uom_code';
      RAISE no_param_expt;
    END IF;
    -- ���Z���[�g
    IF ( i_uom_class_conv_rec.conversion_rate IS NULL ) THEN
      -- �G���[
      lv_param_name := 'conversion_rate';
      RAISE no_param_expt;
    END IF;
    --
    lv_from_uom_code := i_uom_class_conv_rec.from_uom_code;
    -- �P�ʃR�[�h�i���Z��j
    IF ( i_uom_class_conv_rec.to_uom_code IS NULL ) THEN
      -- �w�肪�Ȃ��ꍇ�̓P�[�X�Œ�
      lv_to_uom_code := 'CS';
    ELSE
      lv_to_uom_code := i_uom_class_conv_rec.to_uom_code;
    END IF;
    --====================
    -- �P�ʏ��̎擾
    --====================
    -- �P�ʁi���Z���j
    SELECT  muom.unit_of_measure
           ,muom.uom_class
    INTO    lv_from_unit_of_measure
           ,lv_from_uom_class
    FROM    mtl_units_of_measure_vl    muom
    WHERE   muom.uom_code = lv_from_uom_code;
    --
    -- �P�ʁi���Z��j
    SELECT  muom.unit_of_measure
           ,muom.uom_class
    INTO    lv_to_unit_of_measure
           ,lv_to_uom_class
    FROM    mtl_units_of_measure_vl    muom
    WHERE   muom.uom_code = lv_to_uom_code;
    --
    --====================
    -- �o�^�ςݔ���
    --====================
    SELECT  COUNT( mucc.ROWID )
    INTO    ln_exists_cnt
    FROM    mtl_uom_class_conversions    mucc
    WHERE   mucc.inventory_item_id  = i_uom_class_conv_rec.inventory_item_id
    AND     mucc.to_uom_class       = lv_to_uom_class;
    --
    IF ( ln_exists_cnt = 0 ) THEN
      -- �敪�Ԋ��Z�̐V�K�o�^
      INSERT INTO mtl_uom_class_conversions (
        inventory_item_id
       ,from_unit_of_measure
       ,from_uom_code
       ,from_uom_class
       ,to_unit_of_measure
       ,to_uom_code
       ,to_uom_class
       ,conversion_rate
       ,created_by
       ,creation_date
       ,last_updated_by
       ,last_update_date
       ,last_update_login
       ,request_id
       ,program_application_id
       ,program_id
       ,program_update_date
      ) VALUES (
        i_uom_class_conv_rec.inventory_item_id
       ,lv_from_unit_of_measure
       ,lv_from_uom_code
       ,lv_from_uom_class
       ,lv_to_unit_of_measure
       ,lv_to_uom_code
       ,lv_to_uom_class
       ,i_uom_class_conv_rec.conversion_rate
       ,cn_created_by
       ,cd_creation_date
       ,cn_last_updated_by
       ,cd_last_update_date
       ,cn_last_update_login
       ,cn_request_id
       ,cn_program_application_id
       ,cn_program_id
       ,cd_program_update_date);
    ELSE
      SELECT  COUNT( mucc.ROWID )
      INTO    ln_exists_cnt
      FROM    mtl_uom_class_conversions    mucc
      WHERE   mucc.inventory_item_id  = i_uom_class_conv_rec.inventory_item_id
      AND     mucc.to_uom_code        = lv_to_uom_code;
--      --
--      SELECT  COUNT(mucc.ROWID)
--      FROM    mtl_uom_class_conversions    mucc
--      WHERE   mucc.inventory_item_id  = i_uom_class_conv_rec.inventory_item_id
--      AND     mucc.to_unit_of_measure = lv_to_unit_of_measure;
      --
      IF ( ln_exists_cnt = 0 ) THEN
        -- �G���[�o�� �����N���X�̓o�^�͂ł��Ȃ��̂�
        -- �����N���X�Ŋ��Z��R�[�h���قȂ�ꍇ�G���[
        NULL;
      ELSE
        -- �敪�Ԋ��Z�̍X�V
        UPDATE  mtl_uom_class_conversions
        SET     conversion_rate         = i_uom_class_conv_rec.conversion_rate
               ,last_updated_by         = cn_last_updated_by
               ,last_update_date        = cd_last_update_date
               ,last_update_login       = cn_last_update_login
               ,request_id              = cn_request_id
               ,program_application_id  = cn_program_application_id
               ,program_id              = cn_program_id
               ,program_update_date     = cd_program_update_date
        WHERE   inventory_item_id       = i_uom_class_conv_rec.inventory_item_id
        AND     to_uom_code             = lv_to_uom_code
        AND     to_uom_class            = lv_to_uom_class;
        --
      END IF;
    END IF;
  EXCEPTION
--
    -- *** �p�����[�^�����͗�O�n���h�� ***
    WHEN no_param_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00421            -- ���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_value                  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_param_name                 -- �g�[�N���l1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_uom_class_ref;
--
  /**********************************************************************************
   * Procedure Name   : proc_conc_request
   * Description      : �R���J�����g���s
   **********************************************************************************/
  PROCEDURE proc_conc_request(
    iv_appl_short_name  IN         VARCHAR2                 -- 1.�A�v���P�[�V�����Z�k���y�K�{�z
   ,iv_program          IN         VARCHAR2                 -- 2.�R���J�����g�v���O�����Z�k���y�K�{�z
   ,iv_description      IN         VARCHAR2 DEFAULT NULL    -- 3.�E�v�y�w��s�v�z
   ,iv_start_time       IN         VARCHAR2 DEFAULT NULL    -- 4.�v���J�n����(DD-MON-YY HH24:MI[:SS])�y�w��s�v�z
   ,ib_sub_request      IN         BOOLEAN  DEFAULT FALSE   -- 5.�T�u���N�G�X�g�y�w��s�v�z
   ,i_argument_tab      IN         conc_argument_ttype      -- 6.�R���J�����g�p�����[�^�y�C�Ӂz
   ,iv_wait_flag        IN         VARCHAR2 DEFAULT 'Y'     -- 7.�R���J�����g���s�҂��t���O
   ,on_request_id       OUT        NUMBER                   -- 8.�v��ID
   ,ov_errbuf           OUT NOCOPY VARCHAR2                 -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT NOCOPY VARCHAR2                 -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT NOCOPY VARCHAR2                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
--
--###########################  �Œ蕔 START   ###########################
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'proc_conc_request';    -- �v���O������
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                        VARCHAR2(5000);        -- �G���[�E���b�Z�[�W
    lv_retcode                       VARCHAR2(1);           -- ���^�[���E�R�[�h
    lv_errmsg                        VARCHAR2(5000);        -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_param_name                    VARCHAR2(60);
--
    ln_request_id                    fnd_concurrent_requests.request_id%TYPE;
    lb_ret                           BOOLEAN;
    --
    -- �R���J�����g���s�҂� OUT�ϐ�
    lv_ret_phase                     VARCHAR2(100);         -- �t�F�[�Y(JA)
    lv_ret_status                    VARCHAR2(100);         -- �X�e�[�^�X(JA)
    lv_ret_dev_phase                 VARCHAR2(100);         -- �t�F�[�Y(US)
    lv_ret_dev_status                VARCHAR2(100);         -- �X�e�[�^�X(US)
    lv_ret_message                   VARCHAR2(2000);        -- �������b�Z�[�W
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    no_param_expt                    EXCEPTION;  -- �p�����[�^�����̓G���[
    conc_exec_expt                   EXCEPTION;  -- �R���J�����g�N���G���[
--ito->20090213 Add
    conc_wait_expt                   EXCEPTION;  -- �R���J�����g�ҋ@�G���[
    conc_process_expt                EXCEPTION;  -- �R���J�����g�����G���[
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --=====================
    -- �p�����[�^�`�F�b�N
    --=====================
    IF ( iv_appl_short_name IS NULL ) THEN
      -- �G���[
      lv_param_name := 'iv_appl_short_name';
      RAISE no_param_expt;
    END IF;
    --
    IF ( iv_program IS NULL ) THEN
      -- �G���[
      lv_param_name := 'iv_program';
      RAISE no_param_expt;
    END IF;
    --
    --=====================
    -- �R���J�����g�N��
    --=====================
    ln_request_id := fnd_request.submit_request(
      application => iv_appl_short_name               -- 1.�A�v���P�[�V�����Z�k��
     ,program     => iv_program                       -- 2.�R���J�����g�v���O�����Z�k��
     ,description => iv_description                   -- 3.�E�v
     ,start_time  => iv_start_time                    -- 4.�v���J�n����(DD-MON-YY HH24:MI[:SS])
     ,sub_request => ib_sub_request                   -- 5.�T�u���N�G�X�g
     -- 6.�ȉ��A���s�R���J�����g�v���O�����̃p�����[�^
     ,argument1   => NVL( i_argument_tab(1).argument,   CHR(0) )
     ,argument2   => NVL( i_argument_tab(2).argument,   CHR(0) )
     ,argument3   => NVL( i_argument_tab(3).argument,   CHR(0) )
     ,argument4   => NVL( i_argument_tab(4).argument,   CHR(0) )
     ,argument5   => NVL( i_argument_tab(5).argument,   CHR(0) )
     ,argument6   => NVL( i_argument_tab(6).argument,   CHR(0) )
     ,argument7   => NVL( i_argument_tab(7).argument,   CHR(0) )
     ,argument8   => NVL( i_argument_tab(8).argument,   CHR(0) )
     ,argument9   => NVL( i_argument_tab(9).argument,   CHR(0) )
     ,argument10  => NVL( i_argument_tab(10).argument,  CHR(0) )
     ,argument11  => NVL( i_argument_tab(11).argument,  CHR(0) )
     ,argument12  => NVL( i_argument_tab(12).argument,  CHR(0) )
     ,argument13  => NVL( i_argument_tab(13).argument,  CHR(0) )
     ,argument14  => NVL( i_argument_tab(14).argument,  CHR(0) )
     ,argument15  => NVL( i_argument_tab(15).argument,  CHR(0) )
     ,argument16  => NVL( i_argument_tab(16).argument,  CHR(0) )
     ,argument17  => NVL( i_argument_tab(17).argument,  CHR(0) )
     ,argument18  => NVL( i_argument_tab(18).argument,  CHR(0) )
     ,argument19  => NVL( i_argument_tab(19).argument,  CHR(0) )
     ,argument20  => NVL( i_argument_tab(20).argument,  CHR(0) )
     ,argument21  => NVL( i_argument_tab(21).argument,  CHR(0) )
     ,argument22  => NVL( i_argument_tab(22).argument,  CHR(0) )
     ,argument23  => NVL( i_argument_tab(23).argument,  CHR(0) )
     ,argument24  => NVL( i_argument_tab(24).argument,  CHR(0) )
     ,argument25  => NVL( i_argument_tab(25).argument,  CHR(0) )
     ,argument26  => NVL( i_argument_tab(26).argument,  CHR(0) )
     ,argument27  => NVL( i_argument_tab(27).argument,  CHR(0) )
     ,argument28  => NVL( i_argument_tab(28).argument,  CHR(0) )
     ,argument29  => NVL( i_argument_tab(29).argument,  CHR(0) )
     ,argument30  => NVL( i_argument_tab(30).argument,  CHR(0) )
     ,argument31  => NVL( i_argument_tab(31).argument,  CHR(0) )
     ,argument32  => NVL( i_argument_tab(32).argument,  CHR(0) )
     ,argument33  => NVL( i_argument_tab(33).argument,  CHR(0) )
     ,argument34  => NVL( i_argument_tab(34).argument,  CHR(0) )
     ,argument35  => NVL( i_argument_tab(35).argument,  CHR(0) )
     ,argument36  => NVL( i_argument_tab(36).argument,  CHR(0) )
     ,argument37  => NVL( i_argument_tab(37).argument,  CHR(0) )
     ,argument38  => NVL( i_argument_tab(38).argument,  CHR(0) )
     ,argument39  => NVL( i_argument_tab(39).argument,  CHR(0) )
     ,argument40  => NVL( i_argument_tab(40).argument,  CHR(0) )
     ,argument41  => NVL( i_argument_tab(41).argument,  CHR(0) )
     ,argument42  => NVL( i_argument_tab(42).argument,  CHR(0) )
     ,argument43  => NVL( i_argument_tab(43).argument,  CHR(0) )
     ,argument44  => NVL( i_argument_tab(44).argument,  CHR(0) )
     ,argument45  => NVL( i_argument_tab(45).argument,  CHR(0) )
     ,argument46  => NVL( i_argument_tab(46).argument,  CHR(0) )
     ,argument47  => NVL( i_argument_tab(47).argument,  CHR(0) )
     ,argument48  => NVL( i_argument_tab(48).argument,  CHR(0) )
     ,argument49  => NVL( i_argument_tab(49).argument,  CHR(0) )
     ,argument50  => NVL( i_argument_tab(50).argument,  CHR(0) )
     ,argument51  => NVL( i_argument_tab(51).argument,  CHR(0) )
     ,argument52  => NVL( i_argument_tab(52).argument,  CHR(0) )
     ,argument53  => NVL( i_argument_tab(53).argument,  CHR(0) )
     ,argument54  => NVL( i_argument_tab(54).argument,  CHR(0) )
     ,argument55  => NVL( i_argument_tab(55).argument,  CHR(0) )
     ,argument56  => NVL( i_argument_tab(56).argument,  CHR(0) )
     ,argument57  => NVL( i_argument_tab(57).argument,  CHR(0) )
     ,argument58  => NVL( i_argument_tab(58).argument,  CHR(0) )
     ,argument59  => NVL( i_argument_tab(59).argument,  CHR(0) )
     ,argument60  => NVL( i_argument_tab(60).argument,  CHR(0) )
     ,argument61  => NVL( i_argument_tab(61).argument,  CHR(0) )
     ,argument62  => NVL( i_argument_tab(62).argument,  CHR(0) )
     ,argument63  => NVL( i_argument_tab(63).argument,  CHR(0) )
     ,argument64  => NVL( i_argument_tab(64).argument,  CHR(0) )
     ,argument65  => NVL( i_argument_tab(65).argument,  CHR(0) )
     ,argument66  => NVL( i_argument_tab(66).argument,  CHR(0) )
     ,argument67  => NVL( i_argument_tab(67).argument,  CHR(0) )
     ,argument68  => NVL( i_argument_tab(68).argument,  CHR(0) )
     ,argument69  => NVL( i_argument_tab(69).argument,  CHR(0) )
     ,argument70  => NVL( i_argument_tab(70).argument,  CHR(0) )
     ,argument71  => NVL( i_argument_tab(71).argument,  CHR(0) )
     ,argument72  => NVL( i_argument_tab(72).argument,  CHR(0) )
     ,argument73  => NVL( i_argument_tab(73).argument,  CHR(0) )
     ,argument74  => NVL( i_argument_tab(74).argument,  CHR(0) )
     ,argument75  => NVL( i_argument_tab(75).argument,  CHR(0) )
     ,argument76  => NVL( i_argument_tab(76).argument,  CHR(0) )
     ,argument77  => NVL( i_argument_tab(77).argument,  CHR(0) )
     ,argument78  => NVL( i_argument_tab(78).argument,  CHR(0) )
     ,argument79  => NVL( i_argument_tab(79).argument,  CHR(0) )
     ,argument80  => NVL( i_argument_tab(80).argument,  CHR(0) )
     ,argument81  => NVL( i_argument_tab(81).argument,  CHR(0) )
     ,argument82  => NVL( i_argument_tab(82).argument,  CHR(0) )
     ,argument83  => NVL( i_argument_tab(83).argument,  CHR(0) )
     ,argument84  => NVL( i_argument_tab(84).argument,  CHR(0) )
     ,argument85  => NVL( i_argument_tab(85).argument,  CHR(0) )
     ,argument86  => NVL( i_argument_tab(86).argument,  CHR(0) )
     ,argument87  => NVL( i_argument_tab(87).argument,  CHR(0) )
     ,argument88  => NVL( i_argument_tab(88).argument,  CHR(0) )
     ,argument89  => NVL( i_argument_tab(89).argument,  CHR(0) )
     ,argument90  => NVL( i_argument_tab(90).argument,  CHR(0) )
     ,argument91  => NVL( i_argument_tab(91).argument,  CHR(0) )
     ,argument92  => NVL( i_argument_tab(92).argument,  CHR(0) )
     ,argument93  => NVL( i_argument_tab(93).argument,  CHR(0) )
     ,argument94  => NVL( i_argument_tab(94).argument,  CHR(0) )
     ,argument95  => NVL( i_argument_tab(95).argument,  CHR(0) )
     ,argument96  => NVL( i_argument_tab(96).argument,  CHR(0) )
     ,argument97  => NVL( i_argument_tab(97).argument,  CHR(0) )
     ,argument98  => NVL( i_argument_tab(98).argument,  CHR(0) )
     ,argument99  => NVL( i_argument_tab(99).argument,  CHR(0) )
     ,argument100 => NVL( i_argument_tab(100).argument, CHR(0) )
    );
    -- OUT�p�����[�^�Z�b�g
    on_request_id := ln_request_id;
    --
    --�R���J�����g�N���`�F�b�N
    IF ( ln_request_id <= 0 ) THEN
--ito->20090206 Add(ROLLBACK)
      ROLLBACK;
      -- �N�����s
      RAISE conc_exec_expt;
    END IF;
    --
--ito->20090206 Add(COMMIT)
    COMMIT;
    --
    -- �R���J�����g���s�҂�����
    IF ( iv_wait_flag = 'Y' ) THEN
      --=====================
      -- �R���J�����g�ҋ@
      --=====================
      lb_ret := fnd_concurrent.wait_for_request(
        request_id => ln_request_id               -- 1.�v��ID
       ,interval   => cn_interval                 -- 2.�Ď��Ԋu(�b)
       ,phase      => lv_ret_phase                -- 3.�t�F�[�Y(JA)
       ,status     => lv_ret_status               -- 4.�X�e�[�^�X(JA)
       ,dev_phase  => lv_ret_dev_phase            -- 5.�t�F�[�Y(US)
       ,dev_status => lv_ret_dev_status           -- 6.�X�e�[�^�X(US)
       ,message    => lv_ret_message              -- 7.�������b�Z�[�W
      );
      --
      -- �������ʃ`�F�b�N
      IF ( lb_ret = FALSE ) THEN
--ito->20090213 ��O�����ύX
        RAISE conc_wait_expt;
      END IF;
      --
--ito->20090213 �����ǉ��A��O�����ύX
      IF (( NVL(lv_ret_dev_phase, 'NULL') <> cv_dev_phase_complete )
        OR ( NVL(lv_ret_dev_status, 'NULL') <> cv_dev_status_normal )) THEN
        RAISE conc_process_expt;
      END IF;
    END IF;
    --
  EXCEPTION
--
    -- *** �p�����[�^�����͗�O�n���h�� ***
    WHEN no_param_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00421            -- ���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_value                  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_param_name                 -- �g�[�N���l1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
    -- *** �R���J�����g�N����O�n���h�� ***
    WHEN conc_exec_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00422            -- ���b�Z�[�W
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
--ito->20090213 Add START
    -- *** �R���J�����g�ҋ@��O�n���h�� ***
    WHEN conc_wait_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_name_xxcmm              -- �A�v���P�[�V�����Z�k��
                    ,iv_name        => cv_msg_xxcmm_00426              -- ���b�Z�[�W
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
    -- *** �R���J�����g������O�n���h�� ***
    WHEN conc_process_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg (
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00427            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_dev_phase              -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_ret_dev_phase              -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_dev_status             -- �g�[�N���R�[�h2
                    ,iv_token_value2 => lv_ret_dev_status             -- �g�[�N���l2
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
--ito->20090213 Add END
--
--###########################  �Œ蕔 START #######################################################
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    --
  END proc_conc_request;
--
--###########################  �Œ蕔 END   #######################################################
--
  /**********************************************************************************
   * Procedure Name   : ins_opm_item
   * Description      : OPM�i�ړo�^����
   **********************************************************************************/
  --
  PROCEDURE ins_opm_item(
    i_opm_item_rec      IN         ic_item_mst_b%ROWTYPE,  -- OPM�i�ڃ��R�[�h�^�C�v
    ov_errbuf           OUT NOCOPY VARCHAR2,               -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,               -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'ins_opm_item';    -- �v���O������
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                        VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                       VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                        VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    lv_row_id                        VARCHAR2(2000);
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    --
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --====================
    -- OPM�i�ړo�^
    --====================
  ic_item_mst_pkg.insert_row(
    x_rowid                    => lv_row_id,
    x_item_id                  => i_opm_item_rec.item_id,
    x_item_no                  => i_opm_item_rec.item_no,
    x_alt_itema                => i_opm_item_rec.alt_itema,
    x_alt_itemb                => i_opm_item_rec.alt_itemb,
    x_item_um                  => i_opm_item_rec.item_um,
    x_dualum_ind               => i_opm_item_rec.dualum_ind,
    x_item_um2                 => i_opm_item_rec.item_um2,
    x_deviation_lo             => i_opm_item_rec.deviation_lo,
    x_deviation_hi             => i_opm_item_rec.deviation_hi,
    x_level_code               => i_opm_item_rec.level_code,
    x_lot_ctl                  => i_opm_item_rec.lot_ctl,
    x_lot_indivisible          => i_opm_item_rec.lot_indivisible,
    x_sublot_ctl               => i_opm_item_rec.sublot_ctl,
    x_loct_ctl                 => i_opm_item_rec.loct_ctl,
    x_noninv_ind               => i_opm_item_rec.noninv_ind,
    x_match_type               => i_opm_item_rec.match_type,
    x_inactive_ind             => i_opm_item_rec.inactive_ind,
    x_inv_type                 => i_opm_item_rec.inv_type,
    x_shelf_life               => i_opm_item_rec.shelf_life,
    x_retest_interval          => i_opm_item_rec.retest_interval,
    x_gl_class                 => i_opm_item_rec.gl_class,
    x_inv_class                => i_opm_item_rec.inv_class,
    x_sales_class              => i_opm_item_rec.sales_class,
    x_ship_class               => i_opm_item_rec.ship_class,
    x_frt_class                => i_opm_item_rec.frt_class,
    x_price_class              => i_opm_item_rec.price_class,
    x_storage_class            => i_opm_item_rec.storage_class,
    x_purch_class              => i_opm_item_rec.purch_class,
    x_tax_class                => i_opm_item_rec.tax_class,
    x_customs_class            => i_opm_item_rec.customs_class,
    x_alloc_class              => i_opm_item_rec.alloc_class,
    x_planning_class           => i_opm_item_rec.planning_class,
    x_itemcost_class           => i_opm_item_rec.itemcost_class,
    x_cost_mthd_code           => i_opm_item_rec.cost_mthd_code,
    x_upc_code                 => i_opm_item_rec.upc_code,
    x_grade_ctl                => i_opm_item_rec.grade_ctl,
    x_status_ctl               => i_opm_item_rec.status_ctl,
    x_qc_grade                 => i_opm_item_rec.qc_grade,
    x_lot_status               => i_opm_item_rec.lot_status,
    x_bulk_id                  => i_opm_item_rec.bulk_id,
    x_pkg_id                   => i_opm_item_rec.pkg_id,
    x_qcitem_id                => i_opm_item_rec.qcitem_id,
    x_qchold_res_code          => i_opm_item_rec.qchold_res_code,
    x_expaction_code           => i_opm_item_rec.expaction_code,
    x_fill_qty                 => i_opm_item_rec.fill_qty,
    x_fill_um                  => i_opm_item_rec.fill_um,
    x_planning_category_id     => i_opm_item_rec.planning_category_id,
    x_price_category_id        => i_opm_item_rec.price_category_id,
    x_expaction_interval       => i_opm_item_rec.expaction_interval,
    x_phantom_type             => i_opm_item_rec.phantom_type,
    x_whse_item_id             => i_opm_item_rec.whse_item_id,
    x_experimental_ind         => i_opm_item_rec.experimental_ind,
    x_exported_date            => i_opm_item_rec.exported_date,
    x_trans_cnt                => i_opm_item_rec.trans_cnt,
    x_delete_mark              => i_opm_item_rec.delete_mark,
    x_text_code                => i_opm_item_rec.text_code,
    x_seq_dpnd_class           => i_opm_item_rec.seq_dpnd_class,
    x_commodity_code           => i_opm_item_rec.commodity_code,
    x_request_id               => i_opm_item_rec.request_id,
    x_attribute1               => i_opm_item_rec.attribute1,
    x_attribute2               => i_opm_item_rec.attribute2,
    x_attribute3               => i_opm_item_rec.attribute3,
    x_attribute4               => i_opm_item_rec.attribute4,
    x_attribute5               => i_opm_item_rec.attribute5,
    x_attribute6               => i_opm_item_rec.attribute6,
    x_attribute7               => i_opm_item_rec.attribute7,
    x_attribute8               => i_opm_item_rec.attribute8,
    x_attribute9               => i_opm_item_rec.attribute9,
    x_attribute10              => i_opm_item_rec.attribute10,
    x_attribute11              => i_opm_item_rec.attribute11,
    x_attribute12              => i_opm_item_rec.attribute12,
    x_attribute13              => i_opm_item_rec.attribute13,
    x_attribute14              => i_opm_item_rec.attribute14,
    x_attribute15              => i_opm_item_rec.attribute15,
    x_attribute16              => i_opm_item_rec.attribute16,
    x_attribute17              => i_opm_item_rec.attribute17,
    x_attribute18              => i_opm_item_rec.attribute18,
    x_attribute19              => i_opm_item_rec.attribute19,
    x_attribute20              => i_opm_item_rec.attribute20,
    x_attribute21              => i_opm_item_rec.attribute21,
    x_attribute22              => i_opm_item_rec.attribute22,
    x_attribute23              => i_opm_item_rec.attribute23,
    x_attribute24              => i_opm_item_rec.attribute24,
    x_attribute25              => i_opm_item_rec.attribute25,
    x_attribute26              => i_opm_item_rec.attribute26,
    x_attribute27              => i_opm_item_rec.attribute27,
    x_attribute28              => i_opm_item_rec.attribute28,
    x_attribute29              => i_opm_item_rec.attribute29,
    x_attribute30              => i_opm_item_rec.attribute30,
    x_attribute_category       => i_opm_item_rec.attribute_category,
    x_item_abccode             => i_opm_item_rec.item_abccode,
    x_alloc_category_id        => i_opm_item_rec.alloc_category_id,
    x_customs_category_id      => i_opm_item_rec.customs_category_id,
    x_frt_category_id          => i_opm_item_rec.frt_category_id,
    x_gl_category_id           => i_opm_item_rec.gl_category_id,
    x_inv_category_id          => i_opm_item_rec.inv_category_id,
    x_cost_category_id         => i_opm_item_rec.cost_category_id,
    x_purch_category_id        => i_opm_item_rec.purch_category_id,
    x_sales_category_id        => i_opm_item_rec.sales_category_id,
    x_seq_category_id          => i_opm_item_rec.seq_category_id,
    x_ship_category_id         => i_opm_item_rec.ship_category_id,
    x_storage_category_id      => i_opm_item_rec.storage_category_id,
    x_tax_category_id          => i_opm_item_rec.tax_category_id,
    x_item_desc1               => i_opm_item_rec.item_desc1,
    x_item_desc2               => i_opm_item_rec.item_desc2,
    x_ont_pricing_qty_source   => i_opm_item_rec.ont_pricing_qty_source,
    x_autolot_active_indicator => i_opm_item_rec.autolot_active_indicator,
    x_lot_prefix               => i_opm_item_rec.lot_prefix,
    x_lot_suffix               => i_opm_item_rec.lot_suffix,
    x_sublot_prefix            => i_opm_item_rec.sublot_prefix,
    x_sublot_suffix            => i_opm_item_rec.sublot_suffix,
    x_creation_date            => i_opm_item_rec.creation_date,
    x_created_by               => i_opm_item_rec.created_by,
    x_last_update_date         => i_opm_item_rec.last_update_date,
    x_last_updated_by          => i_opm_item_rec.last_updated_by,
    x_last_update_login        => i_opm_item_rec.last_update_login);
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_opm_item;
--
  /**********************************************************************************
   * Procedure Name   : upd_opm_item
   * Description      : OPM�i�ڍX�V����
   **********************************************************************************/
  --
  PROCEDURE upd_opm_item(
    i_opm_item_rec      IN         ic_item_mst_b%ROWTYPE,  -- OPM�i�ڃ��R�[�h�^�C�v
    ov_errbuf           OUT NOCOPY VARCHAR2,               -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,               -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'upd_opm_item';    -- �v���O������
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                        VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                       VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                        VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    lv_row_id                        VARCHAR2(2000);
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    --
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --====================
    -- OPM�i�ڍX�V
    --====================
  ic_item_mst_pkg.update_row(
    x_item_id                  => i_opm_item_rec.item_id,
    x_item_no                  => i_opm_item_rec.item_no,
    x_alt_itema                => i_opm_item_rec.alt_itema,
    x_alt_itemb                => i_opm_item_rec.alt_itemb,
    x_item_um                  => i_opm_item_rec.item_um,
    x_dualum_ind               => i_opm_item_rec.dualum_ind,
    x_item_um2                 => i_opm_item_rec.item_um2,
    x_deviation_lo             => i_opm_item_rec.deviation_lo,
    x_deviation_hi             => i_opm_item_rec.deviation_hi,
    x_level_code               => i_opm_item_rec.level_code,
    x_lot_ctl                  => i_opm_item_rec.lot_ctl,
    x_lot_indivisible          => i_opm_item_rec.lot_indivisible,
    x_sublot_ctl               => i_opm_item_rec.sublot_ctl,
    x_loct_ctl                 => i_opm_item_rec.loct_ctl,
    x_noninv_ind               => i_opm_item_rec.noninv_ind,
    x_match_type               => i_opm_item_rec.match_type,
    x_inactive_ind             => i_opm_item_rec.inactive_ind,
    x_inv_type                 => i_opm_item_rec.inv_type,
    x_shelf_life               => i_opm_item_rec.shelf_life,
    x_retest_interval          => i_opm_item_rec.retest_interval,
    x_gl_class                 => i_opm_item_rec.gl_class,
    x_inv_class                => i_opm_item_rec.inv_class,
    x_sales_class              => i_opm_item_rec.sales_class,
    x_ship_class               => i_opm_item_rec.ship_class,
    x_frt_class                => i_opm_item_rec.frt_class,
    x_price_class              => i_opm_item_rec.price_class,
    x_storage_class            => i_opm_item_rec.storage_class,
    x_purch_class              => i_opm_item_rec.purch_class,
    x_tax_class                => i_opm_item_rec.tax_class,
    x_customs_class            => i_opm_item_rec.customs_class,
    x_alloc_class              => i_opm_item_rec.alloc_class,
    x_planning_class           => i_opm_item_rec.planning_class,
    x_itemcost_class           => i_opm_item_rec.itemcost_class,
    x_cost_mthd_code           => i_opm_item_rec.cost_mthd_code,
    x_upc_code                 => i_opm_item_rec.upc_code,
    x_grade_ctl                => i_opm_item_rec.grade_ctl,
    x_status_ctl               => i_opm_item_rec.status_ctl,
    x_qc_grade                 => i_opm_item_rec.qc_grade,
    x_lot_status               => i_opm_item_rec.lot_status,
    x_bulk_id                  => i_opm_item_rec.bulk_id,
    x_pkg_id                   => i_opm_item_rec.pkg_id,
    x_qcitem_id                => i_opm_item_rec.qcitem_id,
    x_qchold_res_code          => i_opm_item_rec.qchold_res_code,
    x_expaction_code           => i_opm_item_rec.expaction_code,
    x_fill_qty                 => i_opm_item_rec.fill_qty,
    x_fill_um                  => i_opm_item_rec.fill_um,
    x_planning_category_id     => i_opm_item_rec.planning_category_id,
    x_price_category_id        => i_opm_item_rec.price_category_id,
    x_expaction_interval       => i_opm_item_rec.expaction_interval,
    x_phantom_type             => i_opm_item_rec.phantom_type,
    x_whse_item_id             => i_opm_item_rec.whse_item_id,
    x_experimental_ind         => i_opm_item_rec.experimental_ind,
    x_exported_date            => i_opm_item_rec.exported_date,
    x_trans_cnt                => i_opm_item_rec.trans_cnt,
    x_delete_mark              => i_opm_item_rec.delete_mark,
    x_text_code                => i_opm_item_rec.text_code,
    x_seq_dpnd_class           => i_opm_item_rec.seq_dpnd_class,
    x_commodity_code           => i_opm_item_rec.commodity_code,
    x_request_id               => i_opm_item_rec.request_id,
    x_attribute1               => i_opm_item_rec.attribute1,
    x_attribute2               => i_opm_item_rec.attribute2,
    x_attribute3               => i_opm_item_rec.attribute3,
    x_attribute4               => i_opm_item_rec.attribute4,
    x_attribute5               => i_opm_item_rec.attribute5,
    x_attribute6               => i_opm_item_rec.attribute6,
    x_attribute7               => i_opm_item_rec.attribute7,
    x_attribute8               => i_opm_item_rec.attribute8,
    x_attribute9               => i_opm_item_rec.attribute9,
    x_attribute10              => i_opm_item_rec.attribute10,
    x_attribute11              => i_opm_item_rec.attribute11,
    x_attribute12              => i_opm_item_rec.attribute12,
    x_attribute13              => i_opm_item_rec.attribute13,
    x_attribute14              => i_opm_item_rec.attribute14,
    x_attribute15              => i_opm_item_rec.attribute15,
    x_attribute16              => i_opm_item_rec.attribute16,
    x_attribute17              => i_opm_item_rec.attribute17,
    x_attribute18              => i_opm_item_rec.attribute18,
    x_attribute19              => i_opm_item_rec.attribute19,
    x_attribute20              => i_opm_item_rec.attribute20,
    x_attribute21              => i_opm_item_rec.attribute21,
    x_attribute22              => i_opm_item_rec.attribute22,
    x_attribute23              => i_opm_item_rec.attribute23,
    x_attribute24              => i_opm_item_rec.attribute24,
    x_attribute25              => i_opm_item_rec.attribute25,
    x_attribute26              => i_opm_item_rec.attribute26,
    x_attribute27              => i_opm_item_rec.attribute27,
    x_attribute28              => i_opm_item_rec.attribute28,
    x_attribute29              => i_opm_item_rec.attribute29,
    x_attribute30              => i_opm_item_rec.attribute30,
    x_attribute_category       => i_opm_item_rec.attribute_category,
    x_item_abccode             => i_opm_item_rec.item_abccode,
    x_alloc_category_id        => i_opm_item_rec.alloc_category_id,
    x_customs_category_id      => i_opm_item_rec.customs_category_id,
    x_frt_category_id          => i_opm_item_rec.frt_category_id,
    x_gl_category_id           => i_opm_item_rec.gl_category_id,
    x_inv_category_id          => i_opm_item_rec.inv_category_id,
    x_cost_category_id         => i_opm_item_rec.cost_category_id,
    x_purch_category_id        => i_opm_item_rec.purch_category_id,
    x_sales_category_id        => i_opm_item_rec.sales_category_id,
    x_seq_category_id          => i_opm_item_rec.seq_category_id,
    x_ship_category_id         => i_opm_item_rec.ship_category_id,
    x_storage_category_id      => i_opm_item_rec.storage_category_id,
    x_tax_category_id          => i_opm_item_rec.tax_category_id,
    x_item_desc1               => i_opm_item_rec.item_desc1,
    x_item_desc2               => i_opm_item_rec.item_desc2,
    x_ont_pricing_qty_source   => i_opm_item_rec.ont_pricing_qty_source,
    x_autolot_active_indicator => i_opm_item_rec.autolot_active_indicator,
    x_lot_prefix               => i_opm_item_rec.lot_prefix,
    x_lot_suffix               => i_opm_item_rec.lot_suffix,
    x_sublot_prefix            => i_opm_item_rec.sublot_prefix,
    x_sublot_suffix            => i_opm_item_rec.sublot_suffix,
    x_last_update_date         => i_opm_item_rec.last_update_date,
    x_last_updated_by          => i_opm_item_rec.last_updated_by,
    x_last_update_login        => i_opm_item_rec.last_update_login);
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_opm_item;
--
--
  /**********************************************************************************
   * Procedure Name   : chk_single_byte
   * Description      : ���p�`�F�b�N
   **********************************************************************************/
  --
  FUNCTION chk_single_byte(
    iv_chk_char IN VARCHAR2             --�`�F�b�N�Ώە�����
  )
  RETURN BOOLEAN
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_single_byte'; -- �v���O������
--
  BEGIN
    --NULL�`�F�b�N
    IF (iv_chk_char IS NULL) THEN
      RETURN NULL;
    --���p�`�F�b�N
    ELSIF (LENGTH(iv_chk_char) <> LENGTHB(iv_chk_char)) THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
      RETURN FALSE;
  END chk_single_byte;
--
   /**********************************************************************************
   * Function Name    : get_process_date
   * Description      : �Ɩ����t�擾�֐�
   ***********************************************************************************/
  FUNCTION get_process_date
    RETURN DATE
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_process_date'; -- �v���O������
--
  ld_prdate DATE;
  BEGIN
    --
    SELECT process_date
    INTO   ld_prdate
    FROM   xxccp_process_dates
    ;
    RETURN TRUNC(ld_prdate,'DD');
    --
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB('XXCMM_004COMMON_PKG'||'.'||cv_prg_name||' : '||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
      RETURN NULL;
  END get_process_date;

--
END XXCMM_004COMMON_PKG;
/
