CREATE OR REPLACE PACKAGE BODY XXCMN980001C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN980001C(body)
 * Description      : ���Y�����ڍ׃A�h�I���p�[�W
 * MD.050           : T_MD050_BPO_98A_���Y�����ڍ׃A�h�I���p�[�W
 * Version          : 1.00
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/22   1.00  T.Makuta          �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal   CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_error    CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --�ُ�:2
  cn_request_id      CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cv_date_format     CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
--
  cv_purge_type      CONSTANT VARCHAR2(1)  := '0';                        --�߰������(0:�߰�ފ���)
  cv_purge_code      CONSTANT VARCHAR2(10) := '9801';                     --�߰�ޒ�`����
  cv_doc_type_40     CONSTANT VARCHAR2(2)  := '40';                       --�����^�C�v
  cn_b_status_m1     CONSTANT NUMBER       := -1;
  cn_b_status_m3     CONSTANT NUMBER       := -3;
  cn_b_status_p4     CONSTANT NUMBER       := 4;
--
  --=============
  --���b�Z�[�W
  --=============
  cv_appl_short_name CONSTANT VARCHAR2(10) := 'XXCMN';
  cv_msg_part        CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont        CONSTANT VARCHAR2(3)  := '.';
--
  cv_xxcmn_purge_range      
                     CONSTANT VARCHAR2(50) := 'XXCMN_PURGE_RANGE';        --XXCMN:�p�[�W�����W
  --XXCMN:�p�[�W/�o�b�N�A�b�v�����R�~�b�g��
  cv_xxcmn_commit_range     
                     CONSTANT VARCHAR2(50) := 'XXCMN_COMMIT_RANGE';
--
  cv_target_cnt_msg  CONSTANT VARCHAR2(50) := 'APP-XXCMN-11008';          --�Ώی������b�Z�[�W
  cv_normal_cnt_msg  CONSTANT VARCHAR2(50) := 'APP-XXCMN-11009';          --���팏�����b�Z�[�W
  cv_error_rec_msg   CONSTANT VARCHAR2(50) := 'APP-XXCMN-00010';          --�G���[�������b�Z�[�W
  cv_get_priod_msg   CONSTANT VARCHAR2(50) := 'APP-XXCMN-11011';          --�p�[�W���Ԏ擾���s
  cv_get_profile_msg CONSTANT VARCHAR2(50) := 'APP-XXCMN-10002';          --���̧�ْl�擾���s
  cv_token_profile   CONSTANT VARCHAR2(50) := 'NG_PROFILE';               --���̧�َ擾MSG�pİ�ݖ�
  cv_proc_date_msg   CONSTANT VARCHAR2(50) := 'APP-XXCMN-11014';          --�������o��
  cv_par_token       CONSTANT VARCHAR2(10) := 'PAR';                      --������MSG�pİ�ݖ�
--
  cv_others_err_msg  CONSTANT VARCHAR2(50) := 'APP-XXCMN-11026';          --�폜�������s
  cv_token_shori_2   CONSTANT VARCHAR2(10) := 'SHORI';                    --�폜����MSG�pİ�ݖ�
  cv_token_kinou     CONSTANT VARCHAR2(10) := 'KINOUMEI';                 --�폜����MSG�pİ�ݖ�
  cv_token_key_name  CONSTANT VARCHAR2(10) := 'KEYNAME';                  --�폜����MSG�pİ�ݖ�
  cv_token_key       CONSTANT VARCHAR2(10) := 'KEY';                      --�폜����MSG�pİ�ݖ�
  cv_shori_2         CONSTANT VARCHAR2(50) := '�폜';
  cv_kinou1          CONSTANT VARCHAR2(90) := '���Y�����ڍׁi�A�h�I���j';
  cv_kinou2          CONSTANT VARCHAR2(90) := '�ړ����b�g�ڍׁi�A�h�I���j';
  cv_kinou3          CONSTANT VARCHAR2(90) := '���Y�o�b�`�w�b�_�i�W���j';
  cv_key_name        CONSTANT VARCHAR2(50) := '�o�b�`ID';
--
  cv_normal_msg      CONSTANT VARCHAR2(50) := 'APP-XXCCP1-90004';         --����I�����b�Z�[�W
  cv_error_msg       CONSTANT VARCHAR2(50) := 'APP-XXCCP1-90006';         --�G���[�I���S۰��ޯ�
--
  --TBL_NAME SHORI �����F CNT ��
  cv_end_msg         CONSTANT VARCHAR2(50) := 'APP-XXCMN-11040';          --�������e�o��
  cv_token_tblname   CONSTANT VARCHAR2(10) := 'TBL_NAME';
  cv_tblname_s       CONSTANT VARCHAR2(90) := '���Y�����ڍׁi�A�h�I���j';
  cv_tblname_i       CONSTANT VARCHAR2(90) := '�ړ����b�g�ڍׁi�A�h�I���j';
  cv_token_shori     CONSTANT VARCHAR2(10) := 'SHORI';
  cv_shori           CONSTANT VARCHAR2(50) := '�폜';
  cv_cnt_token       CONSTANT VARCHAR2(10) := 'CNT';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                                       -- �Ώی���
  gn_normal_cnt             NUMBER;                                       -- ���팏��
  gn_error_cnt              NUMBER;                                       -- �G���[����
--
  --�폜����(�A�h�I���e�[�u��)
  gn_del_cnt_mdtl           NUMBER;                                       --���Y�����ڍ�
  gn_del_cnt_lot            NUMBER;                                       --�ړ����b�g�ڍ�
  --���R�~�b�g�폜����(�A�h�I���e�[�u��)
  gn_del_cnt_yet_mdtl       NUMBER;                                       --���Y�����ڍ�
  gn_del_cnt_yet_lot        NUMBER;                                       --�ړ����b�g�ڍ�
--
  gn_cnt_header_yet         NUMBER;                                       --���R�~�b�g��������
  gt_b_hdr_id               gme_batch_header.batch_id%TYPE;
  gt_b_hdr_id_lock          gme_batch_header.batch_id%TYPE;
  gt_m_dtl_addon_id         xxwip_material_detail.mtl_detail_addon_id%TYPE;
  gt_mov_lot_dtl_id         xxinv_mov_lot_details.mov_lot_dtl_id%TYPE;
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
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  local_process_expt        EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN980001C';  -- �p�b�P�[�W��
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
    iv_proc_date  IN  VARCHAR2,     --   1.������
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf               VARCHAR2(5000);                      -- �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1);                         -- ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000);                      -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_purge_period         NUMBER;                              -- �p�[�W����
    ld_standard_date        DATE;                                -- ���
    ln_commit_range         NUMBER;                              -- �����R�~�b�g��
    ln_purge_range          NUMBER;                              -- �p�[�W�����W
    lv_process_part         VARCHAR2(1000);                      -- ������
    ln_shori_flg           NUMBER;
    lv_errmsg_kinou         VARCHAR2(90);                        -- �G���[���b�Z�[�W�o�͗p
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    /*
    CURSOR ���Y�o�b�`�w�b�_�擾
      id_���       IN DATE,
      in_�p�[�W�����W IN NUMBER
    IS
      SELECT ���Y�o�b�`�w�b�_.�o�b�`ID
      FROM   ���Y�o�b�`�w�b�_
      WHERE  ���Y�o�b�`�w�b�_.�v��J�n�� >= id_���  - in_�p�[�W�����W
      AND    ���Y�o�b�`�w�b�_.�v��J�n�� <  id_���
      AND    ���Y�o�b�`�w�b�_.�o�b�`�X�e�[�^�X IN(-1,-3,4)
      ;
    */
    CURSOR b_header_cur(
      id_standard_date      DATE
     ,in_purge_range        NUMBER
    )
    IS
      SELECT /*+ INDEX(gbh GME_GBH_N01) */
              gbh.batch_id            AS batch_id,
              gbh.batch_status        AS batch_status
      FROM    gme_batch_header           gbh                    --���Y�ޯ�ͯ��
      WHERE   gbh.plan_start_date     >= id_standard_date - in_purge_range
      AND     gbh.plan_start_date     <  id_standard_date
      AND     gbh.batch_status IN(cn_b_status_m1,cn_b_status_m3,cn_b_status_p4)
      ;
--
    /*
    CURSOR �p�[�W�Ώې��Y�����ڍ�(�A�h�I��)�擾
      it_�o�b�`ID IN ���Y�o�b�`�w�b�_.�o�b�`ID%TYPE
    IS
      SELECT ���Y�����ڍ�(�A�h�I��).���Y�����ڍ׃A�h�I��ID
      FROM   ���Y�����ڍ�,
             ���Y�����ڍ�(�A�h�I��),
             ���Y�����ڍ�(�A�h�I��)�o�b�N�A�b�v
      WHERE  ���Y�����ڍ�.�o�b�`ID         =  it_�o�b�`ID
      AND    ���Y�����ڍ�.���Y�����ڍ�ID   =  ���Y�����ڍ�(�A�h�I��).���Y�����ڍ׃A�h�I��ID
      AND    ���Y�����ڍ�(�A�h�I��).���Y�����ڍ׃A�h�I��ID = 
                                    ���Y�����ڍ�(�A�h�I��)�o�b�N�A�b�v.���Y�����ڍ׃A�h�I��ID ;
    */
    CURSOR mdtl_addn_cur(
      it_batch_id  gme_batch_header.batch_id%TYPE
    )
    IS
      SELECT /*+ INDEX(gmd GME_MATERIAL_DETAILS_U1) */
              xmd.mtl_detail_addon_id AS mtl_detail_addon_id
      FROM    gme_material_details       gmd,                    --���Y�����ڍ�
              xxwip_material_detail      xmd,                    --���Y�����ڍ�(��޵�)
              xxcmn_material_detail_arc  xmda                    --���Y�����ڍ�(��޵�)�ޯ�����
      WHERE   gmd.batch_id             = it_batch_id
      AND     gmd.material_detail_id   = xmd.material_detail_id
      AND     xmd.mtl_detail_addon_id  = xmda.mtl_detail_addon_id
      ;
--
    /*
    CURSOR �p�[�W�Ώۈړ����b�g�ڍ�(�A�h�I��)�擾
      it_�o�b�`ID IN ���Y�o�b�`�w�b�_.�o�b�`ID%TYPE
    IS
      SELECT �ړ����b�g�ڍ�(�A�h�I��).���b�g�ڍ�ID
      FROM   ���Y�����ڍ�,
             �ړ����b�g�ڍ�(�A�h�I��),
             �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v
      WHERE  ���Y�����ڍ�.�o�b�`ID         = it_�o�b�`ID
      AND    ���Y�����ڍ�.���Y�����ڍ�ID   = �ړ����b�g�ڍ�(�A�h�I��).����ID
      AND    �ړ����b�g�ڍ�(�A�h�I��).�����^�C�v   = '40' 
      AND    �ړ����b�g�ڍ�(�A�h�I��).���b�g�ڍ�ID = 
                                                 �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v.���b�g�ڍ�ID;
    */
    CURSOR mlot_dtl_cur(
      it_batch_id  gme_batch_header.batch_id%TYPE
    )
    IS
      SELECT /*+ INDEX(gmd GME_MATERIAL_DETAILS_U1) */
              xmld.mov_lot_dtl_id     AS mov_lot_dtl_id
      FROM    gme_material_details       gmd,                    --���Y�����ڍ�
              xxinv_mov_lot_details      xmld,                   --�ړ����b�g�ڍ�(��޵�)
              xxcmn_mov_lot_details_arc  xmlda                   --�ړ����b�g�ڍ�(��޵�)�ޯ�����
      WHERE   gmd.batch_id             = it_batch_id
      AND     gmd.material_detail_id   = xmld.mov_line_id
      AND     xmld.document_type_code  = cv_doc_type_40
      AND     xmld.mov_lot_dtl_id      = xmlda.mov_lot_dtl_id
      ;
    -- <�J�[�\����>���R�[�h�^
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode        := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt       := 0;
    gn_normal_cnt       := 0;
    gn_error_cnt        := 0;
    gn_del_cnt_mdtl     := 0;
    gn_del_cnt_lot      := 0;
    gn_del_cnt_yet_mdtl := 0;
    gn_del_cnt_yet_lot  := 0;
    gn_cnt_header_yet   := 0;
--
    -- ���[�J���ϐ��̏�����
    lv_errmsg_kinou     := NULL;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================================
    -- �p�[�W���Ԏ擾
    -- ===============================================
   /*
    ln_�p�[�W���� := �o�b�N�A�b�v����/�p�[�W���Ԏ擾�֐�(cv_�p�[�W�^�C�v,cv_�p�[�W�R�[�h);
     */
    ln_purge_period := xxcmn_common4_pkg.get_purge_period(cv_purge_type, cv_purge_code);
--
    /*
    ln_�p�[�W���Ԃ�NULL�̏ꍇ
      ov_�G���[���b�Z�[�W := xxcmn_common_pkg.get_msg(
                            iv_�A�v���P�[�V�����Z�k��  => cv_appl_short_name
                           ,iv_���b�Z�[�W�R�[�h        => cv_get_priod_msg
                          );
      ov_���^�[���R�[�h := cv_status_error;
      RAISE local_process_expt ��O����
     */
    IF ( ln_purge_period IS NULL ) THEN
--
      --�p�[�W���Ԃ̎擾�Ɏ��s���܂����B
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_priod_msg
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    -- ===============================================
    -- �h�m�p�����[�^�̊m�F
    -- ===============================================
    lv_process_part := 'IN�p�����[�^�̊m�F�F';
--
    /*
    iv_proc_date��NULL�̏ꍇ
      ld_��� := �������擾���ʊ֐����擾���������� - ln_�p�[�W����;
--
    iv_proc_date��NULL�łȂ��ꍇ
      ld_��� := TO_DATE(iv_proc_date) - ln_�p�[�W����;
     */
    IF ( iv_proc_date IS NULL ) THEN
--
      ld_standard_date := xxcmn_common4_pkg.get_syori_date - ln_purge_period;
--
    ELSE
--
      ld_standard_date := TO_DATE(iv_proc_date, cv_date_format) - ln_purge_period;
--
    END IF;
--
    -- ===============================================
    -- �v���t�@�C���E�I�v�V�����l�擾
    -- ===============================================
    lv_process_part := '�v���t�@�C���E�I�v�V�����l�擾�i' || cv_xxcmn_commit_range || '�j�F';
    /*
    ln_�����R�~�b�g�� := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(XXCMN:�p�[�W�����R�~�b�g��);
    */
    ln_commit_range := TO_NUMBER(fnd_profile.value(cv_xxcmn_commit_range));
--
    /* ln_�����R�~�b�g����NULL�̏ꍇ
         ov_�G���[���b�Z�[�W := xxcmn_common_pkg.get_msg(
                     iv_�A�v���P�[�V�����Z�k��  => cv_appl_short_name
                    ,iv_���b�Z�[�W�R�[�h        => cv_get_profile_msg
                    ,iv_�g�[�N����1             => cv_token_profile
                    ,iv_�g�[�N���l1             => cv_xxcmn_commit_range
                   );
         ov_���^�[���R�[�h := cv_status_error;
         RAISE local_process_expt ��O����
    */
    IF ( ln_commit_range IS NULL ) THEN
--
      -- �v���t�@�C��[ NG_PROFILE ]�̎擾�Ɏ��s���܂����B
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_xxcmn_commit_range
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    lv_process_part := '�v���t�@�C���E�I�v�V�����l�擾�i' || cv_xxcmn_purge_range || '�j:';
--
    /*
    ln_�p�[�W�����W := TO_NUMBER(�v���t�@�C���E�I�v�V�����擾(XXCMN:�p�[�W�����W);
    */
    ln_purge_range  := TO_NUMBER(fnd_profile.value(cv_xxcmn_purge_range));
--
    /*
    ln_�p�[�W�����W��NULL�̏ꍇ
    */
    IF ( ln_purge_range IS NULL ) THEN
--
      /*
      ov_�G���[���b�Z�[�W := xxcmn_common_pkg.get_msg(
                     iv_�A�v���P�[�V�����Z�k�� => cv_appl_short_name
                    ,iv_���b�Z�[�W�R�[�h       => cv_get_profile_msg
                    ,iv_�g�[�N����1            => cv_token_profile
                    ,iv_�g�[�N���l1            => cv_xxcmn_purge_range
                   );
      ov_���^�[���R�[�h := cv_status_error;
      RAISE local_process_expt ��O����
      */
--
      -- �v���t�@�C��[ NG_PROFILE ]�̎擾�Ɏ��s���܂����B
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_xxcmn_purge_range
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    lv_process_part := NULL;
--
    -- ===============================================
    -- �又��
    -- ===============================================
    /*
    FOR lr_b_header_rec IN �����Ώې��Y�o�b�`�w�b�_�擾(ld_���,ln_�p�[�W�����W) LOOP
    */
   << purge_main >>
    FOR lr_b_header_rec IN b_header_cur(ld_standard_date
                                       ,ln_purge_range ) LOOP
--
      /*
      ln_�����t���O := 0;
      */
      ln_shori_flg        := 0;
--
      /*
      gt_�Ώې��Y�o�b�`ID := lr_b_header_rec.���Y�o�b�`ID;
      */
      gt_b_hdr_id         := lr_b_header_rec.batch_id;
--
      -- ===============================================
      -- �����R�~�b�g(���Y�o�b�`�w�b�_)
      -- ===============================================
      /*
      NVL(ln_�����R�~�b�g��, 0) <> 0�̏ꍇ
       */
      IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
--
        /* gn_���R�~�b�g��������(���Y�o�b�`�w�b�_) > 0 ���� 
           MOD(gn_���R�~�b�g��������(���Y�o�b�`�w�b�_), ln_�����R�~�b�g��) = 0�̏ꍇ
        */
        IF (  (gn_cnt_header_yet > 0)
          AND (MOD(gn_cnt_header_yet, ln_commit_range) = 0)
           )
        THEN
            /*
            COMMIT;
            */
            COMMIT;
            /*
            gn_�폜����(���Y�����ڍ�(��޵�)) := gn_�폜����(���Y�����ڍ�(��޵�)) + 
                                                gn_���R�~�b�g�폜����(���Y�����ڍ�(��޵�))
            gn_���R�~�b�g�폜����(���Y�����ڍ�(��޵�)) := 0;
            ln_���R�~�b�g��������(���Y�o�b�`�w�b�_)    := 0;
            */
            gn_del_cnt_mdtl     := gn_del_cnt_mdtl + gn_del_cnt_yet_mdtl;
            gn_del_cnt_yet_mdtl := 0;
--
            /*
            gn_�폜����(�ړ����b�g�ڍ�(��޵�)) := gn_�폜����(�ړ����b�g�ڍ�(��޵�)) + 
                                                  gn_���R�~�b�g�폜����(�ړ����b�g�ڍ�(��޵�));
            gn_���R�~�b�g�폜����(�ړ����b�g�ڍ�(��޵�)) := 0;
            */
            gn_del_cnt_lot      := gn_del_cnt_lot + gn_del_cnt_yet_lot;
            gn_del_cnt_yet_lot  := 0;
--
            /*
            gn_���R�~�b�g��������(���Y�o�b�`�w�b�_)    := 0;
            */
            gn_cnt_header_yet   := 0;
--
        END IF;
--
      END IF;
--
      -- ===============================================
      -- �p�[�W�Ώې��Y�����ڍ�(�A�h�I��)�擾
      -- ===============================================
      /*
      FOR lr_mdtl_addn_rec IN �p�[�W�Ώې��Y�����ڍ�(�A�h�I��)�擾
                                                                 (lr_b_header_rec.�o�b�`ID) LOOP
      */
      << purge_mdtl_addn >>
      FOR lr_mdtl_addn_rec IN mdtl_addn_cur(lr_b_header_rec.batch_id) LOOP
--
        /* �Ώی����́A���Y�����ڍ�(��޵�)�̌������g�p����
        gn_�Ώی��� := gn_�Ώی��� + 1;
        */
        gn_target_cnt        := gn_target_cnt + 1;
--
        -- ==========================================================
        -- �����Ώې��Y�����ڍׁi�A�h�I���j�A�o�b�N�A�b�v���Ƀ��b�N
        -- ==========================================================
        /*
        ln_�����t���O := 1;
--
        SELECT ���Y�����ڍ�.���Y�����ڍ׃A�h�I��ID
        INTO   gt_���Y�����ڍ׃A�h�I��ID
        FROM   ���Y�����ڍׁi�A�h�I���j,
               ���Y�����ڍׁi�A�h�I���j�o�b�N�A�b�v
        WHERE  ���Y�����ڍ׃A�h�I��ID = lr_mdtl_addn_rec.���Y�����ڍ׃A�h�I��ID
        AND    ���Y�����ڍׁi�A�h�I���j.���Y�����ڍ׃A�h�I��ID = 
                            ���Y�����ڍׁi�A�h�I���j�o�b�N�A�b�v.���Y�����ڍ׃A�h�I��ID
        FOR UPDATE NOWAIT
        */
--
        ln_shori_flg               := 1;
--
        SELECT  xmd.mtl_detail_addon_id   AS mtl_detail_addon_id
        INTO    gt_m_dtl_addon_id
        FROM    xxwip_material_detail     xmd,
                xxcmn_material_detail_arc xmda
        WHERE   xmd.mtl_detail_addon_id = lr_mdtl_addn_rec.mtl_detail_addon_id
        AND     xmd.mtl_detail_addon_id = xmda.mtl_detail_addon_id
        FOR UPDATE NOWAIT
        ;
--
        -- ===============================================
        -- ���Y�����ڍ�(�A�h�I��)�p�[�W
        -- ===============================================
        /*
        DELETE FROM ���Y�����ڍ�(�A�h�I��)
        WHERE ���Y�����ڍ׃A�h�I��ID = lr_mdtl_addn_rec.���Y�����ڍ׃A�h�I��ID
        */
        DELETE FROM xxwip_material_detail
        WHERE  mtl_detail_addon_id = lr_mdtl_addn_rec.mtl_detail_addon_id
        ;
--
        /*
        UPDATE ���Y�����ڍ�(�A�h�I��)�o�b�N�A�b�v
        SET �p�[�W���s�� = SYSDATE
           ,�p�[�W�v��ID = �v��ID
        WHERE ���Y�����ڍ׃A�h�I��ID = lr_mdtl_addn_rec.���Y�����ڍ׃A�h�I��ID
        */
        UPDATE xxcmn_material_detail_arc
        SET    purge_date          = SYSDATE
              ,purge_request_id    = cn_request_id
        WHERE  mtl_detail_addon_id = lr_mdtl_addn_rec.mtl_detail_addon_id
        ;
--
        /*
        gn_���R�~�b�g�폜����(���Y�����ڍ�(��޵�)) := 
                                            gn_���R�~�b�g�폜����(���Y�����ڍ�(��޵�)) + 1;
        */
        gn_del_cnt_yet_mdtl := gn_del_cnt_yet_mdtl + 1;
--
      END LOOP purge_mdtl_addn;
--
      -- ===============================================
      -- �p�[�W�Ώۈړ����b�g�ڍ�(�A�h�I��)�擾
      -- ===============================================
      /*
      FOR lr_mlot_dtl_rec IN �p�[�W�Ώۈړ����b�g�ڍ�(�A�h�I��)�擾
                                                     (lr_b_header_rec.�o�b�`ID) LOOP
      */
      << purge_mlot_dtl >>
      FOR lr_mlot_dtl_rec IN mlot_dtl_cur(lr_b_header_rec.batch_id) LOOP
--
        -- ==========================================================
        -- �����Ώۈړ����b�g�ڍׁi�A�h�I���j�A�o�b�N�A�b�v���Ƀ��b�N
        -- ==========================================================
        /*
        ln_�����t���O := 2;
--
        SELECT �ړ����b�g�ڍ�.���b�g�ڍ�ID
        INTO   gt_���b�g�ڍ�ID
        FROM   �ړ����b�g�ڍׁi�A�h�I���j,
               �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
        WHERE  �ړ����b�g�ڍׁi�A�h�I���j. ���b�g�ڍ�ID = lr_mlot_dtl_rec.���b�g�ڍ�ID
        AND    �ړ����b�g�ڍׁi�A�h�I���j. ���b�g�ڍ�ID = 
                                           �ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v.���b�g�ڍ�ID
        AND    �ړ����b�g�ڍׁi�A�h�I���j. �����^�C�v   = '40'
        FOR UPDATE NOWAIT
        */
--
        ln_shori_flg               := 2;
--
        SELECT  xmld.mov_lot_dtl_id       AS mov_lot_dtl_id
        INTO    gt_mov_lot_dtl_id
        FROM    xxinv_mov_lot_details     xmld,
                xxcmn_mov_lot_details_arc xmlda
        WHERE   xmld.mov_lot_dtl_id     = lr_mlot_dtl_rec.mov_lot_dtl_id
        AND     xmld.mov_lot_dtl_id     = xmlda.mov_lot_dtl_id
        AND     xmlda.document_type_code = cv_doc_type_40
        FOR UPDATE NOWAIT
        ;
--
        -- ===============================================
        -- �ړ����b�g�ڍ�(�A�h�I��)�p�[�W
        -- ===============================================
        /*
        DELETE FROM �ړ����b�g�ڍ�(�A�h�I��)
        WHERE  ���b�g�ڍ�ID = lr_mlot_dtl_rec.���b�g�ڍ�ID
        AND    �����^�C�v   = '40'
        */
        DELETE FROM xxinv_mov_lot_details
        WHERE  mov_lot_dtl_id     = lr_mlot_dtl_rec.mov_lot_dtl_id
        AND    document_type_code = cv_doc_type_40
        ;
--
        /*
        UPDATE �ړ����b�g�ڍ�(�A�h�I��)�o�b�N�A�b�v
        SET   �p�[�W���s�� = SYSDATE
             ,�p�[�W�v��ID = �v��ID
        WHERE ���b�g�ڍ�ID = lr_mlot_dtl_rec.���b�g�ڍ�ID
        AND   �����^�C�v   = '40'
        */
        UPDATE xxcmn_mov_lot_details_arc
        SET    purge_date          = SYSDATE
              ,purge_request_id    = cn_request_id
        WHERE  mov_lot_dtl_id      = lr_mlot_dtl_rec.mov_lot_dtl_id
        AND    document_type_code  = cv_doc_type_40
        ;
        /*
        gn_���R�~�b�g�폜����(�ړ����b�g�ڍ�(��޵�)) := 
                                              gn_���R�~�b�g�폜����(�ړ����b�g�ڍ�(��޵�)) + 1;
        */
        gn_del_cnt_yet_lot  := gn_del_cnt_yet_lot + 1;
--
      END LOOP purge_mlot_dtl;
--
      /* 
      gn_���R�~�b�g��������(���Y�o�b�`�w�b�_) := gn_���R�~�b�g��������(���Y�o�b�`�w�b�_) + 1;
      */
      gn_cnt_header_yet   := gn_cnt_header_yet + 1;
--
      /*
      -- ==========================================================
      -- �����Ώې��Y�o�b�`�w�b�_���b�N
      -- ==========================================================
      /* 
      lr_b_header_rec.batch_status = 4 �ł���
      ln_�����t���O <> 0 �̏ꍇ
      */
      IF ( lr_b_header_rec.batch_status =  cn_b_status_p4  AND
           ln_shori_flg                 <> 0             ) THEN
--
        /*
        ln_�����t���O             := 3;
--
        SELECT ���Y�o�b�`�w�b�_.�o�b�`ID
        INTO   gt_�o�b�`�w�b�_�o�b�`ID
        FROM   ���Y�o�b�`�w�b�_
        WHERE  ���Y�o�b�`�w�b�_.�o�b�`ID         = lr_b_header_rec.���Y�o�b�`ID
        AND    ���Y�o�b�`�w�b�_.�o�b�`�X�e�[�^�X = 4
        FOR UPDATE NOWAIT;
        */
--
        ln_shori_flg              := 3;
--
        SELECT gbh.batch_id        AS batch_id
        INTO   gt_b_hdr_id_lock
        FROM   gme_batch_header       gbh
        WHERE  gbh.batch_id         = lr_b_header_rec.batch_id
        AND    gbh.batch_status     = cn_b_status_p4
        FOR UPDATE NOWAIT;
--
        /*
        UPDATE ���Y�o�b�`�w�b�_
        SET    ���Y�o�b�`�w�b�_.GL�]���t���O     = 1
        WHERE  ���Y�o�b�`�w�b�_.�o�b�`ID         = lr_b_header_rec.batch_id
        AND    ���Y�o�b�`�w�b�_.�o�b�`�X�e�[�^�X = 4
        */
--
        UPDATE gme_batch_header
        SET    gl_posted_ind = 1
        WHERE  batch_id      = lr_b_header_rec.batch_id
        AND    batch_status  = cn_b_status_p4;
--
      END IF;
--
    END LOOP purge_main;
--
    /*
    gn_�폜����(���Y�����ڍ�(��޵�)) := gn_�폜����(���Y�����ڍ�(��޵�)) + 
                                        gn_���R�~�b�g�폜����(���Y�����ڍ�(��޵�))
    gn_���R�~�b�g�폜����(���Y�����ڍ�(��޵�)) := 0;
    */
    gn_del_cnt_mdtl     := gn_del_cnt_mdtl + gn_del_cnt_yet_mdtl;
    gn_del_cnt_yet_mdtl := 0;
--
    /*
    gn_�폜����(�ړ����b�g�ڍ�(��޵�)) := gn_�폜����(�ړ����b�g�ڍ�(��޵�)) + 
                                          gn_���R�~�b�g�폜����(�ړ����b�g�ڍ�(��޵�));
    gn_���R�~�b�g�폜����(�ړ����b�g�ڍ�(��޵�)) := 0;
    */
    gn_del_cnt_lot      := gn_del_cnt_lot + gn_del_cnt_yet_lot;
    gn_del_cnt_yet_lot  := 0;
--
  -- ===============================================
  -- ��O����
  -- ===============================================
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
    WHEN local_process_expt THEN
         NULL;
--
--#################################  �Œ��O������ START   ###################################
--
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
      IF ( gt_b_hdr_id IS NOT NULL ) THEN
--
        IF ( ln_shori_flg = 1 ) THEN
          lv_errmsg_kinou := cv_kinou1;
        ELSIF ( ln_shori_flg = 2 ) THEN
          lv_errmsg_kinou := cv_kinou2;
        ELSIF ( ln_shori_flg = 3 ) THEN
          lv_errmsg_kinou := cv_kinou3;
        END IF;
--
        --SHORI �����Ɏ��s���܂����B�y KINOUMEI �z KEYNAME �F KEY
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_others_err_msg
                      ,iv_token_name1  => cv_token_shori_2
                      ,iv_token_value1 => cv_shori_2
                      ,iv_token_name2  => cv_token_kinou
                      ,iv_token_value2 => lv_errmsg_kinou
                      ,iv_token_name3  => cv_token_key_name
                      ,iv_token_value3 => cv_key_name
                      ,iv_token_name4  => cv_token_key
                      ,iv_token_value4 => TO_CHAR(gt_b_hdr_id)
                     );
--
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_process_part||SQLERRM;
      ov_retcode := cv_status_error;
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_proc_date  IN  VARCHAR2       --   1.������
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
    -- ===============================================
    -- submain�̌Ăяo��(���ۂ̏�����submain�ōs��)
    -- ===============================================
    submain(
       iv_proc_date -- 1.������
      ,lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================================
    -- ���O�o�͏���
    -- ===============================================
    --�p�����[�^(�������F PAR)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_proc_date_msg
                    ,iv_token_name1  => cv_par_token
                    ,iv_token_value1 => iv_proc_date
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --���Y�����ڍׁi�A�h�I���j �폜 �����F CNT ��
    gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_end_msg
                      ,iv_token_name1  => cv_token_tblname
                      ,iv_token_value1 => cv_tblname_s
                      ,iv_token_name2  => cv_token_shori
                      ,iv_token_value2 => cv_shori
                      ,iv_token_name3  => cv_cnt_token
                      ,iv_token_value3 => TO_CHAR(gn_del_cnt_mdtl)
                     );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�ړ����b�g�ڍׁi�A�h�I���j �폜 �����F CNT ��
    gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_end_msg
                      ,iv_token_name1  => cv_token_tblname
                      ,iv_token_value1 => cv_tblname_i
                      ,iv_token_name2  => cv_token_shori
                      ,iv_token_value2 => cv_shori
                      ,iv_token_name3  => cv_cnt_token
                      ,iv_token_value3 => TO_CHAR(gn_del_cnt_lot)
                     );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �Ώی����o��(�Ώی����F CNT ��)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_cnt_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ���팏���o��(���팏���F CNT ��)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_normal_cnt_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_del_cnt_mdtl)      --�폜����
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �G���[�����o��(�G���[�����F CNT ��)
    IF (lv_retcode = cv_status_error) THEN
        gn_error_cnt := 1;
    ELSE
      gn_error_cnt   := 0;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- -----------------------
    --  ��������(submain)
    -- -----------------------
    IF (lv_retcode = cv_status_error) THEN
      --�G���[�o��(�o�͂̕\��)
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
--
    END IF;
--
    -- ===============================================
    -- �I������
    -- ===============================================
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  -- ===============================================
  -- ��O����
  -- ===============================================
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCMN980001C;
/
