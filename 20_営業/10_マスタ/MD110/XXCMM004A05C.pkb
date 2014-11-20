CREATE OR REPLACE PACKAGE BODY XXCMM004A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A05C(body)
 * Description      : �i�ڈꊇ�o�^���[�N�e�[�u���Ɏ捞�܂ꂽ�i�ڈꊇ�o�^�f�[�^��i�ڃe�[�u���ɓo�^���܂��B
 * MD.050           : �i�ڈꊇ�o�^ CMM_004_A05
 * Version          : Issue3.12
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  chk_exists_category    �J�e�S�����݃`�F�b�N
 *  chk_exists_lookup      LOOKUP�\���݃`�F�b�N
 *  proc_comp              �I������ (A-6)
 *  ins_data               �f�[�^�o�^ (A-5)
 *  validate_item          �i�ڈꊇ�o�^���[�N�f�[�^�擾 (A-3)
 *                         �i�ڈꊇ�o�^���[�N�f�[�^�Ó����`�F�b�N (A-4)
 *                            �Echk_exists_lookup
 *                            �Echk_exists_category
 *  get_if_data            �t�@�C���A�b�v���[�hIF�f�[�^�擾 (A-2)
 *  proc_init              �������� (A-1)
 *  submain                ���C�������v���V�[�W��
 *                            �Eproc_init
 *                            �Eget_if_data
 *                            �Evalidate_item
 *                            �Eins_data
 *                            �Eproc_comp
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                            �Esubmain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/01    1.0   K.Ito            main�V�K�쐬
 *  2009/02/06    1.1   K.Ito            TE070�s��C��
 *  2009/02/12    1.2   K.Ito            ���i���i�敪�ANET�̐ݒ���@�ύX
 *  2009/02/13                           �R���J�����g���s���ʔ���C��
 *  2009/02/16    1.3   K.Ito            TE070���r���[�w�E�������f
 *  2009/02/18    1.4   K.Ito            ���i���i�敪�̐ݒ���@
 *  2009/02/24    1.5   K.Ito            �s�ID.No.005:Disc�i�ڃA�h�I���̌����ΏۍX�V���ɃZ�b�g����l��ύX
 *                                                       (SYSDATE -> �Ɩ����t)
 *                                       �Ɩ����t�擾��NULL�`�F�b�N
 *                                       �s�ID.No.006:�q�i�ڂ�Disc�i�ڕύX�����A�h�I���o�^���A
 *                                       �e�l�p�����ڂƂȂ�艿,�c�ƌ���,����Q�̓Z�b�g�s�v
 *  2009/03/17    1.6   N.Nishimura      �{�Џ��i�敪�ɂ���ďd�ʗe�ϋ敪�A�e�ρA�d�ʂ�ݒ肷��悤�ύX
 *                                      �u�K�p�σt���O�v�̏����l���uN�v����uY�v�ɕύX
 *                                       OPM�i�ڃ}�X�^�́u�}�X�^��M�����v��SYSDATE���Z�b�g����
 *                                       OPM�i�ڃ}�X�^�́u�����L���敪�v���Z�b�g����
 *  2009/04/10    1.7   H.Yoshikawa      ��QT1_0215,T1_0219,T1_0220,T1_0437 �Ή�
 *  2009/05/18    1.8   H.Yoshikawa      ��QT1_0317,T1_0318,T1_0322,T1_0737,T1_0906 �Ή�
 *  2009/05/27    1.9   H.Yoshikawa      ��QT1_0219 �đΉ�
 *  2009/06/04    1.10  N.Nishimura      ��QT1_1319 �d�ʂ܂��͗e�ς�NULL�̏ꍇ�A'0'���Z�b�g����悤�ɏC��
 *                                                   �i���R�[�h�̔��p���l�`�F�b�N��ǉ�
 *                                       ��QT1_1323 �i���R�[�h�̂P���ڂ��T�A�U�̏ꍇ�A�u���b�g�v���O�ɐݒ肷��(�v���t�@�C������)
 *  2009/06/11    1.11  N.Nishimura      ��QT1_1366 �i�ڃJ�e�S������(�o�����敪�A�}�[�P�p�Q�R�[�h�A�Q�R�[�h)�ǉ�
 *  2009/07/07    1.12  H.Yoshikawa      ��Q0000364 ���ݒ�W������0�~�o�^�A08�`10�̓o�^��ǉ�
 *  2009/07/24    1.13  Y.Kuboshima      ��Q0000842 OPM�i�ڃA�h�I���}�X�^�̓K�p�J�n���ɃZ�b�g����l��ύX
 *                                                   (�Ɩ����t -> �v���t�@�C��:XXCMM:�K�p�J�n�������l)
 *  2009/08/07    1.14  Y.Kuboshima      ��Q0000862 ���ޕi�ڂ̏ꍇ�A�W���������v�l�������_�񌅂܂ŋ��e����悤�ɏC��
 *  2009/09/07    1.15  Y.Kuboshima      ��Q0000948 ��P�ʂ̃`�F�b�N��ύX
 *                                                   (�{,kg�ȊO�̓G���[ -> LOOKUP(XXCMM_UNITS_OF_MEASURE)�ɑ��݂��Ȃ��ꍇ�̓G���[)
 *                                       ��Q0001258 �i�ڃJ�e�S������(�i�ڋ敪,���O�敪,���i�敪,�i���敪,�H��Q�R�[�h,�o���p�Q�R�[�h)�ǉ�
 *                                                   OPM�i��,OPM�i�ڃA�h�I���ɐݒ肷��l��ǉ�
 *                                                   OPM�i�� ����L/T,�����Ǘ��敪,��\����,�d���P�����o���^�C�v,�����,�d���敪,�����\�����
 *                                                   OPM�i�ڃA�h�I�� �H��Q,�ܖ����ԋ敪,�ܖ�����,�������,�[������,�P�[�X�d�ʗe��,
 *                                                                   �����g�p��,�W������,�^���,���i����,���i���,�p���z��,
 *                                                                   �p���i��,�e��敪,�P�ʋ敪,�I���敪,�g���[�X�敪
 *  2009/10/14    1.16  Y.Kuboshima      ��Q0001370 �ȉ�����0�ȉ��̏ꍇ�A�G���[�Ƃ���悤�ɏC��
 *                                                   �P�[�X�����A�P�[�X���Z�����ANET�A�d��/�̐ρA���e�ʁA��������A�z���A�i��
 *  2009/12/07    1.17  Y.Kuboshima      E_�{�ғ�_00358 �{�Џ��i�敪���u1�F���[�t�v�̏ꍇ��0�����e����悤�ɏC��
 *                                                      �{�Џ��i�敪���u2�F�h�����N�v�̏ꍇ��0�����e���Ȃ��悤�ɏC��
 *  2010/01/04    1.18  Shigeto.Niki     E_�{�ғ�_00614 �ȉ����ڂɂ��Đe�i�ڂ̒l���p�����Ȃ��悤�ɏC��
 *                                                      �d��/�̐�,ITF�R�[�h,�z��,�i��,���i����,�{�[������
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCMM004A05C';                                  -- �p�b�P�[�W��
--
  -- ���b�Z�[�W
  cv_msg_xxcmm_00002     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';                              -- �v���t�@�C���擾�G���[
  --
  cv_msg_xxcmm_00021     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00021';                              -- �t�@�C���A�b�v���[�h���̃m�[�g
  cv_msg_xxcmm_00022     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00022';                              -- CSV�t�@�C�����m�[�g
  cv_msg_xxcmm_00023     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00023';                              -- FILE_ID�m�[�g
  cv_msg_xxcmm_00024     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00024';                              -- �t�H�[�}�b�g�m�[�g
  cv_msg_xxcmm_00028     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00028';                              -- �f�[�^���ڐ��G���[
  --
  cv_msg_xxcmm_00401     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00401';                              -- �p�����[�^NULL�G���[
  cv_msg_xxcmm_00402     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00402';                              -- IF���b�N�擾�G���[
  cv_msg_xxcmm_00403     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00403';                              -- �t�@�C�����ڃ`�F�b�N�G���[
  cv_msg_xxcmm_00404     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00404';                              -- �}�X�^���݃`�F�b�N�G���[
  cv_msg_xxcmm_00405     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00405';                              -- �i�ڏd���G���[
  cv_msg_xxcmm_00406     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00406';                              -- �e�i�ڃX�e�[�^�X�G���[
  cv_msg_xxcmm_00407     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00407';                              -- �f�[�^�o�^�G���[
  cv_msg_xxcmm_00408     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00408';                              -- OPM�i�ڃg���K�[�N���m�[�g
  cv_msg_xxcmm_00409     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00409';                              -- �f�[�^���o�G���[
  cv_msg_xxcmm_00410     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00410';                              -- �i���R�[�h7���K�{�G���[
  cv_msg_xxcmm_00411     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00411';                              -- �i���R�[�h�敪�G���[
  cv_msg_xxcmm_00412     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00412';                              -- ���p�����g�p�֎~�G���[
  cv_msg_xxcmm_00413     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00413';                              -- �S�p�����g�p�֎~�G���[
  cv_msg_xxcmm_00414     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00414';                              -- ����Ώێ����敪�G���[
  cv_msg_xxcmm_00415     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00415';                              -- ��P�ʃG���[
  cv_msg_xxcmm_00416     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00416';                              -- �{�Џ��i�敪�h�����N���K�{�G���[
  cv_msg_xxcmm_00417     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00417';                              -- ���i���i�敪���i���K�{�G���[
  cv_msg_xxcmm_00418     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00418';                              -- �f�[�^�폜�G���[
  cv_msg_xxcmm_00419     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00419';                              -- �e�i�ڕK�{�G���[
  cv_msg_xxcmm_00420     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00420';                              -- ���i���i�敪DFF���ݒ�G���[
-- Ver1.7  2009/04/10  Add  ��QT1_0219 �Ή�
  cv_msg_xxcmm_00428     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00428';                              -- �m�d�s�����G���[
-- End
-- Ver1.8  2009/05/18 Add  T1_0322 �q�i�ڂŏ��i���i�敪���o���ɐe�i�ڂ̏��i���i�敪�Ɣ�r������ǉ�
  cv_msg_xxcmm_00431     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00431';                              -- ���i���i�敪�G���[
-- End
--Ver1.12  2009/07/07  Mod  0000364�Ή�
  cv_msg_xxcmm_00434     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00434';                              -- �c�ƃG���[
--End1.12
-- Ver.1.5 20090224 Add START
  cv_msg_xxcmm_00435     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00435';                              -- �擾���s�G���[
-- Ver.1.5 20090224 Add END
  cv_msg_xxcmm_00438     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00438';                              -- �W�������G���[
  cv_msg_xxcmm_00439     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00439';                              -- �f�[�^���o�G���[
-- 2009/06/04 Ver1.8 ��QT1_1319 Add start
  cv_msg_xxcmm_00474     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00474';                              -- �i���R�[�h���l�G���[
-- 2009/06/04 Ver1.8 ��QT1_1319 End
--
-- 2009/10/14 Ver1.13 ��Q0001370 add start by Y.Kuboshima
  cv_msg_xxcmm_00493     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00493';                              -- ���ڐ��l�s���G���[
-- 2009/10/14 Ver1.13 ��Q0001370 add end by Y.Kuboshima
--
  -- �g�[�N��
  cv_tkn_value           CONSTANT VARCHAR2(20)  := 'VALUE';                                         --
  cv_tkn_ng_profile      CONSTANT VARCHAR2(20)  := 'NG_PROFILE';                                    --
  cv_tkn_up_name         CONSTANT VARCHAR2(20)  := 'UPLOAD_NAME';                                   -- �t�@�C���A�b�v���[�h����
  cv_tkn_file_id         CONSTANT VARCHAR2(20)  := 'FILE_ID';                                       -- �t�@�C��ID
  cv_tkn_file_format     CONSTANT VARCHAR2(20)  := 'FORMAT';                                        -- �t�H�[�}�b�g
  cv_tkn_file_name       CONSTANT VARCHAR2(20)  := 'FILE_NAME';                                     -- �t�@�C����
  cv_tkn_count           CONSTANT VARCHAR2(20)  := 'COUNT';                                         -- ��������
  cv_tkn_table           CONSTANT VARCHAR2(20)  := 'TABLE';                                         -- �e�[�u����
  cv_tkn_key             CONSTANT VARCHAR2(20)  := 'KEY';                                           -- �L�[��
  cv_tkn_errmsg          CONSTANT VARCHAR2(20)  := 'ERR_MSG';                                       -- �G���[���e
  cv_tkn_input_line_no   CONSTANT VARCHAR2(20)  := 'INPUT_LINE_NO';                                 -- �C���^�t�F�[�X�̍s�ԍ�
  cv_tkn_input_item_code CONSTANT VARCHAR2(20)  := 'INPUT_ITEM_CODE';                               -- �C���^�t�F�[�X�̕i���R�[�h
  cv_tkn_input_col_name  CONSTANT VARCHAR2(20)  := 'INPUT_COL_NAME';                                -- �C���^�t�F�[�X�̍��ږ�
  cv_tkn_item_status     CONSTANT VARCHAR2(20)  := 'ITEM_STATUS';                                   -- �i�ڃX�e�[�^�X
  cv_tkn_req_id          CONSTANT VARCHAR2(20)  := 'REQ_ID';                                        -- �v��ID
  cv_tkn_input           CONSTANT VARCHAR2(20)  := 'INPUT';                                         -- ����
  cv_tkn_item_um         CONSTANT VARCHAR2(20)  := 'ITEM_UM';                                       -- ��P��
  cv_tkn_cs_qty          CONSTANT VARCHAR2(20)  := 'PALETTE_MAX_CS_QTY';                            -- �z��
  cv_tkn_step_qty        CONSTANT VARCHAR2(20)  := 'PALETTE_MAX_STEP_QTY';                          -- �i��
  cv_tkn_sp_supplier     CONSTANT VARCHAR2(20)  := 'SP_SUPPLIER_CODE';                              -- ���X�d����
--Ver1.12  2009/07/07  Mod  0000364�Ή�
  cv_tkn_disc_cost       CONSTANT VARCHAR2(20)  := 'DISC_COST';                                     -- �c�ƌ���
--End1.12  
  cv_tkn_opm_cost        CONSTANT VARCHAR2(20)  := 'OPM_COST';                                      -- �W������(���v�l)
  cv_tkn_msg             CONSTANT VARCHAR2(20)  := 'MSG';                                           -- �R���J�����g�I�����b�Z�[�W
-- Ver1.7  2009/04/10  Add  ��QT1_0219 �Ή�
  cv_tkn_nets_uom_code   CONSTANT VARCHAR2(20)  := 'INPUT_NETS_UOM_CODE';                           -- ���e�ʒP��
  cv_tkn_nets            CONSTANT VARCHAR2(20)  := 'INPUT_NETS';                                    -- ���e��
  cv_tkn_inc_num         CONSTANT VARCHAR2(20)  := 'INPUT_INC_NUM';                                 -- �������
-- End
-- Ver1.8  2009/05/18 Add  T1_0322 �q�i�ڂŏ��i���i�敪���o���ɐe�i�ڂ̏��i���i�敪�Ɣ�r������ǉ�
  cv_tkn_item_prd        CONSTANT VARCHAR2(20)  := 'ITEM_PRD_CLASS';                                -- ���i���i�敪
  cv_tkn_par_item_prd    CONSTANT VARCHAR2(25)  := 'PARENT_ITEM_PRD_CLASS';                         -- ���i���i�敪(�e)
-- End
--
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_xxcmm     CONSTANT VARCHAR2(5)   := 'XXCMM';                                         --
  cv_appl_name_xxcmn     CONSTANT VARCHAR2(5)   := 'XXCMN';                                         --
  --
  cv_log                 CONSTANT VARCHAR2(5)   := 'LOG';                                           -- ���O
  cv_output              CONSTANT VARCHAR2(6)   := 'OUTPUT';                                        -- �A�E�g�v�b�g
  --
  cv_file_id             CONSTANT VARCHAR2(20)  := 'FILE_ID';                                       -- �t�@�C��ID
-- Ver1.3 Mod 20090216
  cv_format              CONSTANT VARCHAR2(20)  := '�t�H�[�}�b�g�p�^�[��';                          -- �t�H�[�}�b�g
--  cv_format              CONSTANT VARCHAR2(20)  := 'FORMAT';                                        -- �t�H�[�}�b�g
  cv_lookup_type_upload_obj
                         CONSTANT VARCHAR2(30)  := xxcmm_004common_pkg.cv_lookup_type_upload_obj;   -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
  cv_prof_item_num       CONSTANT VARCHAR2(30)  := 'XXCMM1_004A05_ITEM_NUM';                        -- �i�ڈꊇ�o�^�f�[�^���ڐ�
  cv_lookup_item_def     CONSTANT VARCHAR2(30)  := 'XXCMM1_004A05_ITEM_DEF';                        -- �i�ڈꊇ�o�^�f�[�^���ڒ�`
  cv_lookup_item_defname CONSTANT VARCHAR2(60)  := 'XXCMM:�i�ڈꊇ�o�^�f�[�^���ڐ�';                -- �u�i�ڈꊇ�o�^�f�[�^���ڒ�`�v��
--Ver1.10 2009/06/04 Add start
  cv_prof_lot_ctl        CONSTANT VARCHAR2(30)  := 'XXCMM1_004A01F_INI_LOT_VALUE';                  -- XXCMM:�i�ړo�^���_���b�g�f�t�H���g�l
  cv_lot_ctl_defname     CONSTANT VARCHAR2(60)  := 'XXCMM:�i�ړo�^���_���b�g�f�t�H���g�l';         -- �uXXCMM:�i�ړo�^���_���b�g�f�t�H���g�l�v��
--Ver1.10 End
--Ver1.11 2009/06/11 Add start
  cv_prof_baracha_div    CONSTANT VARCHAR2(30)  := 'XXCMM1_004_INI_BARACHA_DIV';                    -- XXCMM:�o�����敪�����l
  cv_prof_mark_pg        CONSTANT VARCHAR2(30)  := 'XXCMM1_004_INI_MARK_GUN_CODE';                  -- XXCMM:�}�[�P�p�Q�R�[�h�����l
  cv_baracha_div_def     CONSTANT VARCHAR2(60)  := 'XXCMM:�o�����敪�����l';                        -- XXCMM:�o�����敪�����l
  cv_mark_pg_def         CONSTANT VARCHAR2(60)  := 'XXCMM:�}�[�P�p�Q�R�[�h�����l';                  -- XXCMM:�}�[�P�p�Q�R�[�h�����l
--Ver1.11 End
-- 2009/09/07 Ver1.15 ��Q0001258 add start by Y.Kuboshima
  cv_prof_item_div       CONSTANT VARCHAR2(30)  := 'XXCMM1_004_INI_ITEM_DIV';                       -- XXCMM:�i�ڋ敪�����l
  cv_prof_inout_div      CONSTANT VARCHAR2(30)  := 'XXCMM1_004_INI_INOUT_DIV';                      -- XXCMM:���O�敪�����l
  cv_prof_product_div    CONSTANT VARCHAR2(30)  := 'XXCMM1_004_INI_PRODUCT_DIV';                    -- XXCMM:���i�敪�����l
  cv_prof_quality_div    CONSTANT VARCHAR2(30)  := 'XXCMM1_004_INI_QUALITY_DIV';                    -- XXCMM:�i���敪�����l
  cv_prof_fact_pg        CONSTANT VARCHAR2(30)  := 'XXCMM1_004_INI_FACT_GUN_CODE';                  -- XXCMM:�H��Q�R�[�h�����l
  cv_prof_acnt_pg        CONSTANT VARCHAR2(30)  := 'XXCMM1_004_INI_ACNT_GUN_CODE';                  -- XXCMM:�o�����p�Q�R�[�h�����l
  cv_item_div_def        CONSTANT VARCHAR2(60)  := 'XXCMM:�i�ڋ敪�����l';                          -- XXCMM:�i�ڋ敪�����l
  cv_inout_div_def       CONSTANT VARCHAR2(60)  := 'XXCMM:���O�敪�����l';                          -- XXCMM:���O�敪�����l
  cv_product_div_def     CONSTANT VARCHAR2(60)  := 'XXCMM:���i�敪�����l';                          -- XXCMM:���i�敪�����l
  cv_quality_div_def     CONSTANT VARCHAR2(60)  := 'XXCMM:�i���敪�����l';                          -- XXCMM:�i���敪�����l
  cv_fact_pg_def         CONSTANT VARCHAR2(60)  := 'XXCMM:�H��Q�R�[�h�����l';                      -- XXCMM:�H��Q�R�[�h�����l
  cv_acnt_pg_def         CONSTANT VARCHAR2(60)  := 'XXCMM:�o�����p�Q�R�[�h�����l';                  -- XXCMM:�o�����p�Q�R�[�h�����l
-- 2009/09/07 Ver1.15 ��Q0001258 add end by Y.Kuboshima
-- Ver.1.5 20090224 Add START
  cv_process_date        CONSTANT VARCHAR2(30)  := '�Ɩ����t';                                      -- �Ɩ����t
-- Ver.1.5 20090224 Add END
--
-- Ver1.13 2009/07/24 Add Start
  cv_prof_apply_date     CONSTANT VARCHAR2(30)  := 'XXCMM1_004_INI_OPM_APPLY_DATE';                 -- XXCMM:�K�p�J�n�������l
  cv_apply_date_def      CONSTANT VARCHAR2(60)  := 'XXCMM:�K�p�J�n�������l';                        -- XXCMM:�K�p�J�n�������l
-- Ver1.13 End
--
  -- LOOKUP
  cv_lookup_cost_cmpt    CONSTANT VARCHAR2(30)  := 'XXCMM1_COST_CMPT';                              -- OPM�W�������擾����R���|�[�l���g
  --
  cv_lookup_sales_target CONSTANT VARCHAR2(30)  := 'XXCMN_SALES_TARGET_CLASS';                      -- ����Ώ�
  cv_lookup_rate_class   CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_RATE_CLASS';                          -- ���敪
  cv_lookup_nets_uom_code
                         CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_NET_UOM_CODE';                        -- ���e�ʒP��
  cv_lookup_barachakubun CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_BARACHAKUBUN';                        -- �o�����敪
  cv_lookup_product_class
                         CONSTANT VARCHAR2(30)  := 'XXCMN_D02';                                     -- ���i����
  cv_lookup_vessel_group CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_YOKIGUN';                             -- �e��Q
  cv_lookup_new_item_div CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_SHINSYOHINKUBUN';                     -- �V���i�敪
  cv_lookup_acnt_group   CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_KERIGUN';                             -- �o���Q
  cv_lookup_acnt_vessel_group
                         CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_KERIYOKIGUN';                         -- �o���e��Q
  cv_lookup_brand_group  CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_BRANDGUN';                            -- �u�����h�Q
  cv_lookup_senmonten    CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_SENMONTEN_SHIIRESAKI';                -- ���X�d����
-- 2009/09/07 Ver1.15 ��Q0000948 add start by Y.Kuboshima
  cv_lookup_units_of_measure
                         CONSTANT VARCHAR2(30)  := 'XXCMM_UNITS_OF_MEASURE';                        -- ��P��
-- 2009/09/07 Ver1.15 ��Q0000948 add end by Y.Kuboshima
--
  -- TABLE NAME
  cv_table_flv           CONSTANT VARCHAR2(30)  := 'LOOKUP�\';                                      -- FND_LOOKUP_VALUES_VL
  cv_table_mcv           CONSTANT VARCHAR2(30)  := '�J�e�S��';                                      -- MTL_CATEGORIES_VL
  cv_table_iimb          CONSTANT VARCHAR2(30)  := 'OPM�i�ڃ}�X�^';                                 -- IC_ITEM_MST_B
  cv_table_ximb          CONSTANT VARCHAR2(30)  := 'OPM�i�ڃA�h�I��';                               -- XXCMN_ITEM_MST_B
  cv_table_gic_ssk       CONSTANT VARCHAR2(60)  := 'OPM�i�ڃJ�e�S������(���i���i�敪)';             -- GMI_ITEM_CATEGORIES
  cv_table_gic_hsk       CONSTANT VARCHAR2(60)  := 'OPM�i�ڃJ�e�S������(�{�Џ��i�敪)';             -- GMI_ITEM_CATEGORIES
  cv_table_gic_sg        CONSTANT VARCHAR2(60)  := 'OPM�i�ڃJ�e�S������(����Q)';                   -- GMI_ITEM_CATEGORIES
--Ver1.11  2009/06/11 Add Start
  cv_table_gic_bd        CONSTANT VARCHAR2(60)  := 'OPM�i�ڃJ�e�S������(�o�����敪)';               -- GMI_ITEM_CATEGORIES
  cv_table_gic_mgc       CONSTANT VARCHAR2(60)  := 'OPM�i�ڃJ�e�S������(�}�[�P�p�Q�R�[�h)';         -- GMI_ITEM_CATEGORIES
  cv_table_gic_pg        CONSTANT VARCHAR2(60)  := 'OPM�i�ڃJ�e�S������(�Q�R�[�h)';                 -- GMI_ITEM_CATEGORIES
--Ver1.11  2009/06/11 End
-- 2009/09/07 Ver1.15 ��Q0001258 add start by Y.Kuboshima
  cv_table_gic_itd       CONSTANT VARCHAR2(60)  := 'OPM�i�ڃJ�e�S������(�i�ڋ敪)';                 -- GMI_ITEM_CATEGORIES
  cv_table_gic_ind       CONSTANT VARCHAR2(60)  := 'OPM�i�ڃJ�e�S������(���O�敪)';                 -- GMI_ITEM_CATEGORIES
  cv_table_gic_pd        CONSTANT VARCHAR2(60)  := 'OPM�i�ڃJ�e�S������(���i�敪)';                 -- GMI_ITEM_CATEGORIES
  cv_table_gic_qd        CONSTANT VARCHAR2(60)  := 'OPM�i�ڃJ�e�S������(�i���敪)';                 -- GMI_ITEM_CATEGORIES
  cv_table_gic_fpg       CONSTANT VARCHAR2(60)  := 'OPM�i�ڃJ�e�S������(�H��Q�R�[�h)';             -- GMI_ITEM_CATEGORIES
  cv_table_gic_apg       CONSTANT VARCHAR2(60)  := 'OPM�i�ڃJ�e�S������(�o�����p�Q�R�[�h)';         -- GMI_ITEM_CATEGORIES
-- 2009/09/07 Ver1.15 ��Q0001258 add end by Y.Kuboshima
--
  cv_table_ccd           CONSTANT VARCHAR2(30)  := 'OPM�W������';                                   -- CM_CMPT_DTL
  cv_table_xsib          CONSTANT VARCHAR2(30)  := 'Disc�i�ڃA�h�I��';                              -- XXCMM_SYSTEM_ITEMS_B
  cv_table_xsibh         CONSTANT VARCHAR2(30)  := 'Disc�i�ڕύX�����A�h�I��';                      -- XXCMM_SYSTEM_ITEMS_B_HST
  cv_table_xwibr         CONSTANT VARCHAR2(30)  := '�i�ڈꊇ�o�^���[�N';                            -- XXCMM_WK_ITEM_BATCH_REGIST
  cv_tkn_val_file_ul_if  CONSTANT VARCHAR2(30)  := '�t�@�C���A�b�v���[�hIF';                        -- XXCCP_MRP_FILE_UL_INTERFACE
--
  -- ITEM
  cv_item_code           CONSTANT VARCHAR2(30)  := '�i���R�[�h';                                    --
  cv_item_batch_regist   CONSTANT VARCHAR2(30)  := '�i�ڈꊇ�o�^';                                  --
  cv_item_name           CONSTANT VARCHAR2(30)  := '������';                                        --
  cv_item_short_name     CONSTANT VARCHAR2(30)  := '����';                                          --
  cv_item_name_alt       CONSTANT VARCHAR2(30)  := '�J�i';                                          --
  cv_sales_target_flag   CONSTANT VARCHAR2(30)  := '����Ώۋ敪';                                  --
  cv_case_inc_num        CONSTANT VARCHAR2(30)  := '�P�[�X����';                                    --
  cv_item_um             CONSTANT VARCHAR2(30)  := '��P��';                                      --
  cv_item_product_class  CONSTANT VARCHAR2(30)  := '���i���i�敪';                                  --
  cv_rate_class          CONSTANT VARCHAR2(30)  := '���敪';                                        --
  cv_weight_volume_class CONSTANT VARCHAR2(30)  := '�d�ʗe�ϋ敪';                                  --
  cv_weight_volume       CONSTANT VARCHAR2(30)  := '�d�ʁ^�̐�';                                    --
  cv_nets                CONSTANT VARCHAR2(30)  := '���e��';                                        --
  cv_nets_uom_code       CONSTANT VARCHAR2(30)  := '���e�ʒP��';                                    --
  cv_inc_num             CONSTANT VARCHAR2(30)  := '�������';                                      --
  cv_hon_product_class   CONSTANT VARCHAR2(30)  := '�{�Џ��i�敪';                                  --
  cv_baracha_div         CONSTANT VARCHAR2(30)  := '�o�����敪';                                    --
  cv_jan_code            CONSTANT VARCHAR2(30)  := 'JAN�R�[�h';                                     --
  cv_case_jan_code       CONSTANT VARCHAR2(30)  := '�P�[�XJAN�R�[�h';                               --
  cv_itf_code            CONSTANT VARCHAR2(30)  := 'ITF�R�[�h';                                     --
  cv_policy_group        CONSTANT VARCHAR2(30)  := '����Q';                                        --
  cv_list_price          CONSTANT VARCHAR2(30)  := '�艿';                                          --
  cv_standard_price      CONSTANT VARCHAR2(30)  := '�W������';                                      --
  cv_business_price      CONSTANT VARCHAR2(30)  := '�c�ƌ���';                                      --
-- 2009/10/14 ��Q0001370 add start by Y.Kuboshima
  cv_case_conv_inc_num   CONSTANT VARCHAR2(30)  := '�P�[�X���Z����';                                --
  cv_net                 CONSTANT VARCHAR2(30)  := '�m�d�s';                                        --
  cv_pale_max_cs_qty     CONSTANT VARCHAR2(30)  := '�z��';                                          --
  cv_pale_max_step_qty   CONSTANT VARCHAR2(30)  := '�i��';                                          --
-- 2009/10/14 ��Q0001370 add end by Y.Kuboshima
--
  cv_yes                 CONSTANT VARCHAR2(1)   := 'Y';                                             --
  cv_no                  CONSTANT VARCHAR2(1)   := 'N';                                             --
  cv_null_ok             CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_null_ok;                  -- �C�Ӎ���
  cv_null_ng             CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_null_ng;                  -- �K�{����
  cv_varchar             CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_varchar;                  -- ������
  cv_number              CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_number;                   -- ���l
  cv_date                CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_date;                     -- ���t
  cv_varchar_cd          CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_varchar_cd;               -- �����񍀖�
  cv_number_cd           CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_number_cd;                -- ���l����
  cv_date_cd             CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_date_cd;                  -- ���t����
  cv_not_null            CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_not_null;                 -- �K�{
  cv_msg_comma           CONSTANT VARCHAR2(1)   := ',';                                             -- �J���}
  cv_msg_comma_double    CONSTANT VARCHAR2(2)   := '�A';                                            -- �J���}(�S�p)
  cv_max_date            CONSTANT VARCHAR2(10)  := '9999/12/31';                                    -- MAX���t
  cv_date_format_rmd     CONSTANT VARCHAR2(10)  := 'RRRR/MM/DD';                                    --
  cv_date_fmt_std        CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_date_fmt_std;             --
--
--ito->20090213 Add
  cv_status_val_normal   CONSTANT VARCHAR2(10)  := '����';                                          -- ����:0
  cv_status_val_warn     CONSTANT VARCHAR2(10)  := '�x��';                                          -- �x��:1
  cv_status_val_error    CONSTANT VARCHAR2(10)  := '�G���[';                                        -- �G���[:2
--
  -- �i�ڃX�e�[�^�X
  cn_itm_status_num_tmp  CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_num_tmp;       -- ���̔�
  cn_itm_status_pre_reg  CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_pre_reg;       -- ���o�^
  cn_itm_status_regist   CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_regist;        -- �{�o�^
  cn_itm_status_no_sch   CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_no_sch;        -- �p
  cn_itm_status_trn_only CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_trn_only;      -- �c�f
  cn_itm_status_no_use   CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_no_use;        -- �c
--
  -- �R���|�[�l���g�敪
  cv_cost_cmpnt_01gen    CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_01gen;         -- ����
  cv_cost_cmpnt_02sai    CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_02sai;         -- �Đ���
  cv_cost_cmpnt_03szi    CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_03szi;         -- ���ޔ�
  cv_cost_cmpnt_04hou    CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_04hou;         -- ���
  cv_cost_cmpnt_05gai    CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_05gai;         -- �O���Ǘ���
  cv_cost_cmpnt_06hkn    CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_06hkn;         -- �ۊǔ�
  cv_cost_cmpnt_07kei    CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_07kei;         -- ���̑��o��
--
  cv_categ_set_item_prod CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_item_prod;      -- ���i���i�敪
  cv_categ_set_hon_prod  CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_hon_prod;       -- �{�Џ��i�敪
  cv_categ_set_seisakugun
                         CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_seisakugun;     -- ����Q
--Ver1.11  2009/06/11 Add start
  cv_categ_set_baracha_div
                         CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_baracha_div;    -- �o�����敪
  cv_categ_set_mark_pg   CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_mark_pg;        -- �}�[�P�p�Q�R�[�h
  cv_categ_set_gun_code  CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_gun_code;       -- �Q�R�[�h
--Ver1.11  2009/06/11 End
-- 2009/09/07 Ver1.15 ��Q0001258 add start by Y.Kuboshima
  cv_categ_set_item_div  CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_item_div;       -- �i�ڋ敪
  cv_categ_set_inout_div CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_inout_div;      -- ���O�敪
  cv_categ_set_product_div
                         CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_product_div;    -- ���i�敪
  cv_categ_set_quality_div
                         CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_quality_div;    -- �i���敪
  cv_categ_set_fact_pg   CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_fact_pg;        -- �H��Q�R�[�h
  cv_categ_set_acnt_pg   CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_acnt_pg;        -- �o�����p�Q�R�[�h
-- 2009/09/07 Ver1.15 ��Q0001258 add end by Y.Kuboshima
--
  cv_prog_opmitem_trigger
                         CONSTANT VARCHAR2(20)  := 'XXCMN810003C';                                  -- �uOPM�i�ڃg���K�[�N���R���J�����g�v
--
  -- ����Ώ�
  cv_sales_target_0      CONSTANT VARCHAR2(1)   := '0';                                             -- ����ΏۊO
  cv_sales_target_1      CONSTANT VARCHAR2(1)   := '1';                                             -- ����Ώ�
  -- ��P��
-- 2009/09/07 Ver1.15 ��Q0000948 delete start by Y.Kuboshima
--  cn_item_um_hon         CONSTANT VARCHAR2(2)   := '�{';                                            -- �{
--  cn_item_um_kg          CONSTANT VARCHAR2(2)   := 'kg';                                            -- kg
-- 2009/09/07 Ver1.15 ��Q0000948 delete end by Y.Kuboshima
  -- ���i���i�敪
  cn_item_prod_item      CONSTANT NUMBER        := 1;                                               -- ���i
  cn_item_prod_prod      CONSTANT NUMBER        := 2;                                               -- ���i
  -- ���敪
  cn_rate_class_0        CONSTANT NUMBER        := 0;                                               -- �ʏ�
  cn_rate_class_1        CONSTANT NUMBER        := 1;                                               -- ��
  -- �{�Џ��i�敪
  cn_hon_prod_leaf       CONSTANT NUMBER        := 1;                                               -- ���[�t
  cn_hon_prod_drink      CONSTANT NUMBER        := 2;                                               -- �h�����N
  -- �o�����敪
  cn_baracha_etc         CONSTANT NUMBER        := 0;                                               -- ���̑�
  cn_baracha_bara        CONSTANT NUMBER        := 1;                                               -- �o����
--
--��2009/03/13 Add Start
  -- �d�ʗe�ϋ敪
  cv_weight              CONSTANT VARCHAR2(1)   := '1';                                             -- �d��
  cv_volume              CONSTANT VARCHAR2(1)   := '2';                                             -- �e��
--��Add End
---2009/03/17 Add start
  -- �����L���敪
  cv_exam_class_0        CONSTANT NUMBER        := '0';                                             -- �u���v
  cv_exam_class_1        CONSTANT NUMBER        := '1';                                             -- �u�L�v
--Add End
-- 2009/08/07 Ver1.14 ��Q0000862 add start by Y.Kuboshima
  -- ���ޕi��
  cv_leaf_material       CONSTANT VARCHAR2(1)   := '5';                                             -- ���ޕi��(���[�t)
  cv_drink_material      CONSTANT VARCHAR2(1)   := '6';                                             -- ���ޕi��(�h�����N)
-- 2009/08/07 Ver1.14 ��Q0000862 add end by Y.Kuboshima
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE g_item_def_rtype    IS RECORD                                                                -- ���R�[�h�^��錾
      (item_name       VARCHAR2(100)                                                                -- ���ږ�
      ,item_attribute  VARCHAR2(100)                                                                -- ���ڑ���
      ,item_essential  VARCHAR2(100)                                                                -- �K�{�t���O
      ,item_length     NUMBER                                                                       -- ���ڂ̒���(��������)
      ,decim           NUMBER                                                                       -- ���ڂ̒���(�����_�ȉ�)
      );
  --
  TYPE g_parent_item_rtype IS RECORD                                                                -- �e�i�ڒl�p�����R�[�h
      (parent_item_id           ic_item_mst_b.item_id%TYPE                                          -- �i��ID
      ,rate_class               xxcmn_item_mst_b.rate_class%TYPE                                    -- ���敪
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete start by Shigeto.Niki
--      ,palette_max_cs_qty       xxcmn_item_mst_b.palette_max_cs_qty%TYPE                            -- �z��
--      ,palette_max_step_qty     xxcmn_item_mst_b.palette_max_step_qty%TYPE                          -- �p���b�g����ő�i��
--      ,product_class            xxcmn_item_mst_b.product_class%TYPE                                 -- ���i����
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete end by Shigeto.Niki
      ,nets                     xxcmm_system_items_b.nets%TYPE                                      -- ���e��
      ,nets_uom_code            xxcmm_system_items_b.nets_uom_code%TYPE                             -- ���e�ʒP��
      ,inc_num                  xxcmm_system_items_b.inc_num%TYPE                                   -- �������
      ,vessel_group             xxcmm_system_items_b.vessel_group%TYPE                              -- �e��Q
      ,acnt_group               xxcmm_system_items_b.acnt_group%TYPE                                -- �o���Q
      ,acnt_vessel_group        xxcmm_system_items_b.acnt_vessel_group%TYPE                         -- �o���e��Q
      ,brand_group              xxcmm_system_items_b.brand_group%TYPE                               -- �u�����h�Q
      ,baracha_div              xxcmm_system_items_b.baracha_div%TYPE                               -- �o�����敪
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete start by Shigeto.Niki
--      ,bowl_inc_num             xxcmm_system_items_b.bowl_inc_num%TYPE                              -- �{�[������
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete end by Shigeto.Niki
      ,case_jan_code            xxcmm_system_items_b.case_jan_code%TYPE                             -- �P�[�XJAN�R�[�h
      ,sp_supplier_code         xxcmm_system_items_b.sp_supplier_code%TYPE                          -- ���X�d����
      ,case_number              VARCHAR2(240)                                                       -- �P�[�X����
-- Ver1.8  2009/05/18 Add  T1_0906 �P�[�X���Z������ǉ�
      ,case_conv_inc_num        xxcmm_system_items_b.case_conv_inc_num%TYPE                         -- �P�[�X���Z����
-- End
      ,net                      VARCHAR2(240)                                                       -- NET
      ,weight_volume_class      VARCHAR2(240)                                                       -- �d�ʗe�ϋ敪
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete start by Shigeto.Niki
--      ,weight_volume            VARCHAR2(240)                                                       -- �d�ʁ^�̐�
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete end by Shigeto.Niki
      ,jan_code                 VARCHAR2(240)                                                       -- JAN�R�[�h
      ,item_um                  ic_item_mst_b.item_um%TYPE                                          -- ��P��
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete start by Shigeto.Niki
--      ,itf_code                 VARCHAR2(240)                                                       -- ITF�R�[�h
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete end by Shigeto.Niki
      ,sales_target             VARCHAR2(240)                                                       -- ����Ώۋ敪
      ,item_product_class       VARCHAR2(240)                                                       -- ���i���i�敪
      ,dualum_ind               ic_item_mst_b.dualum_ind%TYPE                                       -- ��d�Ǘ�
      ,lot_ctl                  ic_item_mst_b.lot_ctl%TYPE                                          -- ���b�g
      ,autolot_active_indicator ic_item_mst_b.autolot_active_indicator%TYPE                         -- �������b�g�̔ԗL��
      ,lot_suffix               ic_item_mst_b.lot_suffix%TYPE                                       -- ���b�g�E�T�t�B�b�N�X
      ,ssk_category_set_id      mtl_category_sets_b.category_set_id%TYPE                            -- �J�e�S���Z�b�gID(���i���i�敪)
      ,ssk_category_id          mtl_categories_b.category_id%TYPE                                   -- �J�e�S��ID(���i���i�敪)
--Ver1.10 2009/06/04 Add start
      ,hon_product_class        VARCHAR2(240)                                                       -- �{�Џ��i�敪
--Ver1.10 2009/06/04 End
      ,hsk_category_set_id      mtl_category_sets_b.category_set_id%TYPE                            -- �J�e�S���Z�b�gID(�{�Џ��i�敪)
      ,hsk_category_id          mtl_categories_b.category_id%TYPE                                   -- �J�e�S��ID(�{�Џ��i�敪)
      ,sg_category_set_id       mtl_category_sets_b.category_set_id%TYPE                            -- �J�e�S���Z�b�gID(����Q)
      ,sg_category_id           mtl_categories_b.category_id%TYPE                                   -- �J�e�S��ID(����Q)
      );
  -- �J�e�S�����(�e�i�ڎ��Ɏg�p)
  TYPE g_item_ctg_rtype    IS RECORD                                                                -- ���R�[�h�^��錾
      (category_set_name        mtl_category_sets_tl.category_set_name%TYPE                         -- �J�e�S����
      ,category_val             VARCHAR2(240)                                                       -- �J�e�S���l
      ,line_no                  VARCHAR2(240)                                                       -- �s�ԍ�
      ,item_code                VARCHAR2(240)                                                       -- �i���R�[�h
      ,ssk_category_id          mtl_categories_b.category_id%TYPE                                   -- �J�e�S��ID(���i���i�敪)
      ,ssk_category_set_id      mtl_category_sets_b.category_set_id%TYPE                            -- �J�e�S���Z�b�gID(���i���i�敪)
      ,dualum_ind               NUMBER                                                              -- ��d�Ǘ�
      ,lot_ctl                  NUMBER                                                              -- ���b�g
      ,autolot_active_indicator NUMBER                                                              -- �������b�g�̔ԗL��
      ,lot_suffix               NUMBER                                                              -- ���b�g�E�T�t�B�b�N�X
      ,hsk_category_id          mtl_categories_b.category_id%TYPE                                   -- �J�e�S��ID(�{�Џ��i�敪)
      ,hsk_category_set_id      mtl_category_sets_b.category_set_id%TYPE                            -- �J�e�S���Z�b�gID(�{�Џ��i�敪)
      ,sg_category_id           mtl_categories_b.category_id%TYPE                                   -- �J�e�S��ID(����Q)
      ,sg_category_set_id       mtl_category_sets_b.category_set_id%TYPE                            -- �J�e�S���Z�b�gID(����Q)
--Ver1.11  2009/06/11 Add start
      ,bd_category_id           mtl_categories_b.category_id%TYPE                                   -- �J�e�S��ID(�o�����敪)
      ,bd_category_set_id       mtl_category_sets_b.category_set_id%TYPE                            -- �J�e�S���Z�b�gID(�o�����敪)
      ,mgc_category_id          mtl_categories_b.category_id%TYPE                                   -- �J�e�S��ID(�}�[�P�p�Q�R�[�h)
      ,mgc_category_set_id      mtl_category_sets_b.category_set_id%TYPE                            -- �J�e�S���Z�b�gID(�}�[�P�p�Q�R�[�h)
      ,pg_category_id           mtl_categories_b.category_id%TYPE                                   -- �J�e�S��ID(�Q�R�[�h)
      ,pg_category_set_id       mtl_category_sets_b.category_set_id%TYPE                            -- �J�e�S���Z�b�gID(�Q�R�[�h)
--Ver1.11 End
-- 2009/09/07 Ver1.15 ��Q0001258 add start by Y.Kuboshima
      ,itd_category_id          mtl_categories_b.category_id%TYPE                                   -- �J�e�S��ID(�i�ڋ敪)
      ,itd_category_set_id      mtl_category_sets_b.category_set_id%TYPE                            -- �J�e�S���Z�b�gID(�i�ڋ敪)
      ,ind_category_id          mtl_categories_b.category_id%TYPE                                   -- �J�e�S��ID(���O�敪)
      ,ind_category_set_id      mtl_category_sets_b.category_set_id%TYPE                            -- �J�e�S���Z�b�gID(���O�敪)
      ,pd_category_id           mtl_categories_b.category_id%TYPE                                   -- �J�e�S��ID(���i�敪)
      ,pd_category_set_id       mtl_category_sets_b.category_set_id%TYPE                            -- �J�e�S���Z�b�gID(���i�敪)
      ,qd_category_id           mtl_categories_b.category_id%TYPE                                   -- �J�e�S��ID(�i���敪)
      ,qd_category_set_id       mtl_category_sets_b.category_set_id%TYPE                            -- �J�e�S���Z�b�gID(�i���敪)
      ,fpg_category_id          mtl_categories_b.category_id%TYPE                                   -- �J�e�S��ID(�H��Q�R�[�h)
      ,fpg_category_set_id      mtl_category_sets_b.category_set_id%TYPE                            -- �J�e�S���Z�b�gID(�H��Q�R�[�h)
      ,apg_category_id          mtl_categories_b.category_id%TYPE                                   -- �J�e�S��ID(�o�����p�Q�R�[�h)
      ,apg_category_set_id      mtl_category_sets_b.category_set_id%TYPE                            -- �J�e�S���Z�b�gID(�o�����p�Q�R�[�h)
-- 2009/09/07 Ver1.15 ��Q0001258 add end by Y.Kuboshima
      );
  -- LOOKUP���(�e�i�ڎ��Ɏg�p)
  TYPE g_lookup_rtype    IS RECORD                                                                  -- ���R�[�h�^��錾
      (lookup_type              fnd_lookup_values.lookup_type%TYPE                                  -- LOOKUP_TYPE
      ,lookup_code              fnd_lookup_values.lookup_code%TYPE                                  -- LOOKUP_CODE
      ,meaning                  fnd_lookup_values.meaning%TYPE                                      -- meaning
      ,line_no                  VARCHAR2(240)                                                       -- �s�ԍ�
      ,item_code                VARCHAR2(240)                                                       -- �i���R�[�h
      );
  -- ���̑����
  TYPE g_etc_rtype       IS RECORD                                                                  -- ���R�[�h�^��錾
      (nets_uom_code            fnd_lookup_values.lookup_type%TYPE                                  -- ���e�ʒP�ʂ�LOOKUP_CODE
      );
  --
  TYPE g_item_def_ttype   IS TABLE OF g_item_def_rtype      INDEX BY BINARY_INTEGER;                -- �e�[�u���^�̐錾
  --
  TYPE g_check_data_ttype IS TABLE OF VARCHAR2(4000)        INDEX BY BINARY_INTEGER;                -- �e�[�u���^�̐錾
--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_file_id                NUMBER;                                                                 -- �p�����[�^�i�[�p�ϐ�
  gv_format                 VARCHAR2(100);                                                          -- �p�����[�^�i�[�p�ϐ�
  gn_item_num               NUMBER;                                                                 -- �i�ڈꊇ�o�^�f�[�^���ڐ��i�[�p
  gd_process_date           DATE;                                                                   -- �Ɩ����t
  g_item_def_tab            g_item_def_ttype;                                                       -- �e�[�u���^�ϐ��̐錾
--Ver1.10 2009/06/04 Add start
  gn_lot_ctl                NUMBER;                                                                 -- XXCMM:�i�ړo�^���_���b�g�f�t�H���g�l�i�[�p
--Ver1.10 End
--Ver1.11 2009/06/11 Add start
  gn_baracha_div            NUMBER;                                                                 -- XXCMM:�o�����敪�����l
  gv_mark_pg                VARCHAR2(4);                                                            -- XXCMM:�}�[�P�p�Q�R�[�h
--Ver1.11 End
--Ver1.13 2009/07/26 Add Start
  gd_opm_apply_date         DATE;                                                                   -- XXCMM:�K�p�J�n�������l
--Ver1.13 End
-- 2009/09/07 Ver1.15 ��Q0001258 add start by Y.Kuboshima
  gv_item_div               VARCHAR2(1);                                                            -- XXCMM:�i�ڋ敪�����l
  gv_inout_div              VARCHAR2(1);                                                            -- XXCMM:���O�敪�����l
  gv_product_div            VARCHAR2(1);                                                            -- XXCMM:���i�敪�����l
  gv_quality_div            VARCHAR2(1);                                                            -- XXCMM:�i���敪�����l
  gv_fact_pg                VARCHAR2(4);                                                            -- XXCMM:�H��Q�R�[�h�����l
  gv_acnt_pg                VARCHAR2(4);                                                            -- XXCMM:�o�����p�Q�R�[�h�����l
-- 2009/09/07 Ver1.15 ��Q0001258 add end by Y.Kuboshima
  --
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --*** ���b�N�G���[��O ***
  global_check_lock_expt     EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : chk_exists_category
   * Description      : �J�e�S�����݃`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_exists_category(
    io_item_ctg_rec      IN  OUT g_item_ctg_rtype  -- 1.�J�e�S�����
   ,ov_errbuf            OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode           OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg            OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_exists_category'; -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_sql                    VARCHAR2(5000);                         -- ���ISQL������
    ln_cnt                    NUMBER;                                 -- ���o����
    lv_sqlerrm                VARCHAR2(5000);                         -- SQLERRM�ϐ��ޔ�p
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    -- LOOKUP�\���ISQL�쐬
    --==============================================================
    lv_sql :=           'SELECT mcv.category_id ';                              -- �J�e�S��ID
    lv_sql := lv_sql || '      ,mcsv.category_set_id ';                         -- �J�e�S���Z�b�gID
    --
    -- ���i���i�敪�̏ꍇ
    IF ( io_item_ctg_rec.category_set_name = cv_categ_set_item_prod ) THEN
      lv_sql := lv_sql || '      ,TO_NUMBER(mcv.attribute1) ';                  -- ��d�Ǘ�
      lv_sql := lv_sql || '      ,TO_NUMBER(mcv.attribute2) ';                  -- ���b�g
      lv_sql := lv_sql || '      ,TO_NUMBER(mcv.attribute3) ';                  -- �������b�g�̔ԗL��
      lv_sql := lv_sql || '      ,TO_NUMBER(mcv.attribute4) ';                  -- ���b�g�E�T�t�B�b�N�X
    END IF;
    --
    lv_sql := lv_sql || '  FROM mtl_categories_vl mcv ';                        -- �J�e�S��
    lv_sql := lv_sql || '      ,mtl_category_sets_vl mcsv ';                    -- �J�e�S���Z�b�g
    lv_sql := lv_sql || ' WHERE mcv.structure_id       = mcsv.structure_id ';
    lv_sql := lv_sql || '   AND mcsv.category_set_name = '''  ||  io_item_ctg_rec.category_set_name  || '''';      -- �J�e�S���Z�b�g��
    lv_sql := lv_sql || '   AND mcv.segment1           = '''  ||  io_item_ctg_rec.category_val       || '''';      -- �J�e�S���l
    --
    -- ���ISQL���s
    BEGIN
      -- ���i���i�敪�̏ꍇ
      IF ( io_item_ctg_rec.category_set_name = cv_categ_set_item_prod ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.ssk_category_id
                                     ,io_item_ctg_rec.ssk_category_set_id
                                     ,io_item_ctg_rec.dualum_ind
                                     ,io_item_ctg_rec.lot_ctl
                                     ,io_item_ctg_rec.autolot_active_indicator
                                     ,io_item_ctg_rec.lot_suffix
                                     ;
      --
      -- �{�Џ��i�敪�̏ꍇ
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_hon_prod ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.hsk_category_id
                                     ,io_item_ctg_rec.hsk_category_set_id
                                     ;
      --
      -- ����Q�̏ꍇ
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_seisakugun ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.sg_category_id
                                     ,io_item_ctg_rec.sg_category_set_id
                                     ;
--Ver1.11  2009/06/11 Add start
      --
      -- �o�����敪�̏ꍇ
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_baracha_div ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.bd_category_id
                                     ,io_item_ctg_rec.bd_category_set_id
                                     ;
      --
      -- �}�[�P�p�Q�R�[�h�̏ꍇ
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_mark_pg ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.mgc_category_id
                                     ,io_item_ctg_rec.mgc_category_set_id
                                     ;
      --
      -- �Q�R�[�h�̏ꍇ
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_gun_code ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.pg_category_id
                                     ,io_item_ctg_rec.pg_category_set_id
                                     ;
--Ver1.11  2009/06/11 End
-- 2009/09/07 ��Q0001258 add start by Y.Kuboshima
      -- �i�ڋ敪�̏ꍇ
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_item_div ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.itd_category_id
                                     ,io_item_ctg_rec.itd_category_set_id
                                     ;
      -- ���O�敪�̏ꍇ
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_inout_div ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.ind_category_id
                                     ,io_item_ctg_rec.ind_category_set_id
                                     ;
      -- ���i�敪�̏ꍇ
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_product_div ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.pd_category_id
                                     ,io_item_ctg_rec.pd_category_set_id
                                     ;
      -- �i���敪�̏ꍇ
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_quality_div ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.qd_category_id
                                     ,io_item_ctg_rec.qd_category_set_id
                                     ;
      -- �H��Q�R�[�h�̏ꍇ
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_fact_pg ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.fpg_category_id
                                     ,io_item_ctg_rec.fpg_category_set_id
                                     ;
      -- �o�����p�Q�R�[�h�̏ꍇ
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_acnt_pg ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.apg_category_id
                                     ,io_item_ctg_rec.apg_category_set_id
                                     ;
-- 2009/09/07 ��Q0001258 add end by Y.Kuboshima
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_sqlerrm := SQLERRM;
        ln_cnt := 0;
    END;
    --
    -- �������ʃ`�F�b�N
    IF ( ln_cnt = 0 ) THEN
      -- �f�[�^���o�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm                                          -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00409                                          -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_table                                                -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_table_mcv || '(' || io_item_ctg_rec.category_set_name || ')'       -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_input_line_no                                        -- �g�[�N���R�[�h2
                    ,iv_token_value2 => io_item_ctg_rec.line_no                                     -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_input_item_code                                      -- �g�[�N���R�[�h3
                    ,iv_token_value3 => io_item_ctg_rec.item_code                                   -- �g�[�N���l3
                    ,iv_token_name4  => cv_tkn_errmsg                                               -- �g�[�N���R�[�h4
                    ,iv_token_value4 => lv_sqlerrm                                                  -- �g�[�N���l4
                   );
      -- ���b�Z�[�W�o��
      xxcmm_004common_pkg.put_message(
        iv_message_buff => lv_errmsg
       ,ov_errbuf       => lv_errbuf
       ,ov_retcode      => lv_retcode
       ,ov_errmsg       => lv_errmsg
      );
      --
      ov_retcode := cv_status_error;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_exists_category;
--
  /**********************************************************************************
   * Procedure Name   : chk_exists_lookup
   * Description      : LOOKUP�\���݃`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_exists_lookup(
    io_lookup_rec  IN  OUT g_lookup_rtype    -- 1.LOOKUP���
   ,ov_errbuf      OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_exists_lookup'; -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_sql                    VARCHAR2(5000);                         -- ���ISQL������
    ln_cnt                    NUMBER;                                 -- ���o����
    lv_lookup_code            fnd_lookup_values.lookup_code%TYPE;     -- ���oLOOKUP_CODE
    lv_sqlerrm                VARCHAR2(5000);                         -- SQLERRM�ϐ��ޔ�p
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    -- LOOKUP�\���ISQL�쐬
    --==============================================================
    lv_sql :=           'SELECT flvv.lookup_code ';
    lv_sql := lv_sql || '  FROM fnd_lookup_values_vl flvv ';                    -- LOOKUP�\
    lv_sql := lv_sql || ' WHERE flvv.lookup_type   = :v1_lookup_type ';         -- LOOKUP_TYPE
    --
    -- ���e�ʒP�ʂ̏ꍇ�̂ݏ�������e�Ƃ��܂��B
    IF ( io_lookup_rec.lookup_type = cv_lookup_nets_uom_code ) THEN
      lv_sql := lv_sql || '   AND flvv.meaning       = :v2_meaning ';           -- MEANING
    ELSE
      lv_sql := lv_sql || '   AND flvv.lookup_code   = :v2_lookup_code ';       -- LOOKUP_CODE
    END IF;
    --
-- Ver1.7  2009/04/10  Mod  ��QT1_0220 �Ή�
--    -- �e��Q�A�o���e��Q�A�u�����h�Q��(NOT LIKE '%*')�������t�����܂��B
--    IF ( io_lookup_rec.lookup_type IN ( cv_lookup_vessel_group
--                                       ,cv_lookup_acnt_vessel_group
--                                       ,cv_lookup_brand_group )) THEN
--      lv_sql := lv_sql || '   AND flvv.lookup_code   NOT LIKE ''%*'' ';         -- LOOKUP_CODE
--    -- �o���Q��(NOT LIKE '%**')�������t�����܂��B
--    ELSIF ( io_lookup_rec.lookup_type = cv_lookup_acnt_group ) THEN
--      lv_sql := lv_sql || '   AND flvv.lookup_code   NOT LIKE ''%**'' ';        -- LOOKUP_CODE
--    END IF;
    --
    -- �e��Q�A�o���e��Q�A�u�����h�Q�A�o���Q�̏ꍇ�A(NOT LIKE '%*')�������t�����܂��B
    IF ( io_lookup_rec.lookup_type IN ( cv_lookup_vessel_group
                                       ,cv_lookup_acnt_vessel_group
                                       ,cv_lookup_brand_group
                                       ,cv_lookup_acnt_group )) THEN
      lv_sql := lv_sql || '   AND flvv.lookup_code   NOT LIKE ''%*'' ';         -- LOOKUP_CODE
    END IF;
-- End
    --
    lv_sql := lv_sql || '   AND flvv.enabled_flag  = :v3_flag        ';         -- �g�p�\�t���O
    lv_sql := lv_sql || '   AND NVL( flvv.start_date_active, :v4_process_date ) <= :v5_process_date ';   -- �K�p�J�n��
    lv_sql := lv_sql || '   AND NVL( flvv.end_date_active,   :v6_process_date ) >= :v7_process_date ';   -- �K�p�I����
    --
    --
    -- ���ISQL���s
    BEGIN
      -- ���e�ʒP�ʂ̏ꍇ�̂ݏ�������e�Ƃ��܂��B
      IF ( io_lookup_rec.lookup_type = cv_lookup_nets_uom_code ) THEN
        EXECUTE IMMEDIATE lv_sql
        INTO  lv_lookup_code
        USING io_lookup_rec.lookup_type
             ,io_lookup_rec.meaning
             ,cv_yes
             ,gd_process_date
             ,gd_process_date
             ,gd_process_date
             ,gd_process_date
        ;
      ELSE
        EXECUTE IMMEDIATE lv_sql
        INTO  lv_lookup_code
        USING io_lookup_rec.lookup_type
             ,io_lookup_rec.lookup_code
             ,cv_yes
             ,gd_process_date
             ,gd_process_date
             ,gd_process_date
             ,gd_process_date
        ;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_sqlerrm := SQLERRM;
        lv_lookup_code := NULL;
    END;
    --
    -- �������ʃ`�F�b�N
    IF ( lv_lookup_code IS NULL ) THEN
      -- �f�[�^���o�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm                                          -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00409                                          -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_table                                                -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_table_flv || '(' || io_lookup_rec.lookup_type || ')'                -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_input_line_no                                        -- �g�[�N���R�[�h2
                    ,iv_token_value2 => io_lookup_rec.line_no                                                  -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_input_item_code                                      -- �g�[�N���R�[�h3
                    ,iv_token_value3 => io_lookup_rec.item_code                                                -- �g�[�N���l3
                    ,iv_token_name4  => cv_tkn_errmsg                                               -- �g�[�N���R�[�h4
                    ,iv_token_value4 => lv_sqlerrm                                                  -- �g�[�N���l4
                   );
      -- ���b�Z�[�W�o��
      xxcmm_004common_pkg.put_message(
        iv_message_buff => lv_errmsg
       ,ov_errbuf       => lv_errbuf
       ,ov_retcode      => lv_retcode
       ,ov_errmsg       => lv_errmsg
      );
      --
      ov_retcode := cv_status_error;
    ELSE
      -- ���e�ʒP�ʂ̏ꍇ�̂�LOOKUP_CODE��߂��܂��B
      IF ( io_lookup_rec.lookup_type = cv_lookup_nets_uom_code ) THEN
        io_lookup_rec.lookup_code := lv_lookup_code;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_exists_lookup;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_comp
   * Description      : �I������ (A-6)
   ***********************************************************************************/
  PROCEDURE proc_comp(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_comp'; -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(10);                           -- �X�e�b�v
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
    --
--##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  �Œ蕔 END   ############################
    --
    --==============================================================
    -- A-6.1 �i�ڈꊇ�o�^�f�[�^�폜
    --==============================================================
    BEGIN
      lv_step := 'A-6.1';
      DELETE FROM xxcmm_wk_item_batch_regist
      ;
      --
    EXCEPTION
      -- *** �f�[�^�폜��O�n���h�� ***
      WHEN OTHERS THEN
        --
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00418         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_xwibr             -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_errmsg              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                    -- �g�[�N���l2
                      );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        --
        ov_retcode := cv_status_error;
    END;
    --
    --==============================================================
    -- A-6.2 �t�@�C���A�b�v���[�hIF�e�[�u���f�[�^�폜
    --==============================================================
    BEGIN
      lv_step := 'A-6.2';
      DELETE FROM xxccp_mrp_file_ul_interface
      WHERE  file_id = gn_file_id
      ;
      --
      COMMIT;
      --
    EXCEPTION
      -- *** �f�[�^�폜��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00418          -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table                -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_tkn_val_file_ul_if       -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmsg               -- �g�[�N���R�[�h2
                      ,iv_token_value2 => SQLERRM                     -- �g�[�N���l2
                     );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        --
        ov_retcode := cv_status_error;
    END;
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_comp;
--
  /**********************************************************************************
   * Procedure Name   : ins_data
   * Description      : �f�[�^�o�^ (A-5)
   ***********************************************************************************/
  PROCEDURE ins_data(
    i_wk_item_rec  IN  xxcmm_wk_item_batch_regist%ROWTYPE                  -- �i�ڈꊇ�o�^���[�N���
   ,i_item_ctg_rec IN  g_item_ctg_rtype                                    -- �J�e�S�����
   ,i_etc_rec      IN  g_etc_rtype                                         -- ���̑����
   ,ov_errbuf      OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- *** ���[�J���萔 ***
-- Ver1.7  2009/04/10  Add  ��QT1_0219 �Ή�
    cn_net_uom_code_kg        CONSTANT NUMBER(1) := 2;
    cn_net_uom_code_l         CONSTANT NUMBER(1) := 4;
-- End
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(10);                                     -- �X�e�b�v
    --
    ln_opm_cost_cnt           NUMBER;                                           -- �s�J�E���^(OPM��������)
    ln_conc_cnt               NUMBER;                                           -- �s�J�E���^(�R���J�����g)
    --
    l_opm_item_rec            ic_item_mst_b%ROWTYPE;
    l_ctg_product_prod_rec    xxcmm_004common_pkg.opmitem_category_rtype;       -- ���i���i�敪
    l_ctg_hon_prod_rec        xxcmm_004common_pkg.opmitem_category_rtype;       -- �{�Џ��i�敪
    ln_item_id                ic_item_mst_b.item_id%TYPE;                       -- �V�[�P���XGET�p�i��ID
    ln_item_hst_id            xxcmm_system_items_b_hst.item_hst_id%TYPE;        -- �V�[�P���XGET�p�i�ڕύX����ID
    lv_check_flag             VARCHAR2(1);                                      -- �`�F�b�N�t���O
    ln_cmpnt_cost             cm_cmpt_dtl.cmpnt_cost%TYPE;                      -- ����
    l_set_parent_item_rec     g_parent_item_rtype;                              -- �e�i�ڒl�p�����R�[�h(�Z�b�g�p)
    lv_tkn_table              VARCHAR2(60);
-- Ver.1.5 20090224 Mod START
    ln_fixed_price            xxcmm_system_items_b_hst.fixed_price%TYPE;
    ln_discrete_cost          xxcmm_system_items_b_hst.discrete_cost%TYPE;
    lv_policy_group           xxcmm_system_items_b_hst.policy_group%TYPE;
-- Ver.1.5 20090224 Mod END
--
    ln_parent_item_id         xxcmn_item_mst_b.parent_item_id%TYPE;
--
-- 2009/09/07 Ver1.15 ��Q0001258 add start by Y.Kuboshima
    l_xxcmn_item_rec          xxcmn_item_mst_b%ROWTYPE;
-- 2009/09/07 Ver1.15 ��Q0001258 add end by Y.Kuboshima
--
    -- *** ���[�J���E�J�[�\�� ***
    --
    -- �e�i�ڏ��擾�J�[�\��
    CURSOR parent_item_cur(
      pn_parent_item_id  NUMBER
    )
    IS
      SELECT  ximb.item_id
             ,ximb.rate_class
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete start by Shigeto.Niki
--             ,ximb.palette_max_cs_qty
--             ,ximb.palette_max_step_qty
--             ,ximb.product_class
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete end by Shigeto.Niki
             ,xsib.nets
             ,xsib.nets_uom_code
             ,xsib.inc_num
             ,xsib.vessel_group
             ,xsib.acnt_group
             ,xsib.acnt_vessel_group
             ,xsib.brand_group
             ,xsib.baracha_div
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete start by Shigeto.Niki
--             ,xsib.bowl_inc_num
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete end by Shigeto.Niki
             ,xsib.case_jan_code
             ,xsib.sp_supplier_code
             ,iimb.attribute11   AS case_number
-- Ver1.8  2009/05/18 Add  T1_0906 �P�[�X���Z������ǉ�
             ,xsib.case_conv_inc_num
-- End
             ,iimb.attribute12   AS net
             ,iimb.attribute10   AS weight_volume_class  --2009/03/13 �ǉ�
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete start by Shigeto.Niki
--             ,( CASE iimb.attribute10
--                     WHEN cv_weight THEN iimb.attribute25
--                     WHEN cv_volume THEN iimb.attribute16
--                     ELSE NULL
--               END )             AS weight_volume  -- �d�ʁ^�̐�  2009/03/16 �ǉ�
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete end by Shigeto.Niki
             --,iimb.attribute25   AS weight_volume  2009/03/16 �d�ʗe�ϋ敪�̒ǉ��ɂ���ăR�����g�A�E�g
             ,iimb.attribute21   AS jan_code
             ,iimb.item_um
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete start by Shigeto.Niki
--             ,iimb.attribute22   AS itf_code
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete end by Shigeto.Niki
             ,cv_sales_target_0  AS sales_target  -- �q�i�ڂ̏ꍇ�A�u0:�ΏۊO�v�Œ�
             ,ssk.item_product_class
             ,ssk.dualum_ind
             ,ssk.lot_ctl
             ,ssk.autolot_active_indicator
             ,ssk.lot_suffix
             ,ssk.ssk_category_set_id
             ,ssk.ssk_category_id
--Ver1.10 2009/06/04 Add start
             ,hsk.hon_product_class
--Ver1.10 2009/06/04 End
             ,hsk.hsk_category_set_id
             ,hsk.hsk_category_id
             ,sg.sg_category_set_id
             ,sg.sg_category_id
      FROM    xxcmn_item_mst_b     ximb
             ,ic_item_mst_b        iimb
             ,xxcmm_system_items_b xsib
             ,(SELECT       gicssk.item_id                  AS item_id
                           ,mcssk.segment1                  AS item_product_class
                           ,TO_NUMBER(mcssk.attribute1)     AS dualum_ind
                           ,TO_NUMBER(mcssk.attribute2)     AS lot_ctl
                           ,TO_NUMBER(mcssk.attribute3)     AS autolot_active_indicator
                           ,TO_NUMBER(mcssk.attribute4)     AS lot_suffix
                           ,mcssk.category_id               AS ssk_category_id
                           ,mcsssk.category_set_id          AS ssk_category_set_id
                FROM        gmi_item_categories  gicssk
                           ,mtl_category_sets_vl mcsssk
                           ,mtl_categories_vl    mcssk
                WHERE       gicssk.category_set_id    = mcsssk.category_set_id
                AND         mcsssk.category_set_name  = cv_categ_set_item_prod
                AND         gicssk.category_id        = mcssk.category_id
                AND         gicssk.category_id        = mcssk.category_id
              ) ssk      -- ���i���i�敪
             ,(SELECT       gichsk.item_id                  AS item_id
                           ,mchsk.segment1                  AS hon_product_class
                           ,mchsk.category_id               AS hsk_category_id
                           ,mcshsk.category_set_id          AS hsk_category_set_id
                FROM        gmi_item_categories  gichsk
                           ,mtl_category_sets_vl mcshsk
                           ,mtl_categories_vl    mchsk
                WHERE       gichsk.category_set_id    = mcshsk.category_set_id
                AND         mcshsk.category_set_name  = cv_categ_set_hon_prod
                AND         gichsk.category_id        = mchsk.category_id
                AND         gichsk.category_id        = mchsk.category_id
              ) hsk      -- �{�Џ��i�敪
             ,(SELECT       gicsg.item_id                  AS item_id
                           ,mcsg.segment1                  AS policy_group
                           ,mcsg.category_id               AS sg_category_id
                           ,mcssg.category_set_id          AS sg_category_set_id
                FROM        gmi_item_categories  gicsg
                           ,mtl_category_sets_vl mcssg
                           ,mtl_categories_vl    mcsg
                WHERE       gicsg.category_set_id    = mcssg.category_set_id
                AND         mcssg.category_set_name  = cv_categ_set_seisakugun
                AND         gicsg.category_id        = mcsg.category_id
                AND         gicsg.category_id        = mcsg.category_id
              ) sg       -- ����Q
      WHERE   ximb.item_id = pn_parent_item_id
      AND     ximb.item_id = iimb.item_id
      AND     iimb.item_no = xsib.item_code
      AND     ximb.item_id = ssk.item_id
      AND     ximb.item_id = hsk.item_id
      AND     ximb.item_id = sg.item_id
      AND     ximb.start_date_active <= TRUNC(gd_process_date)
      AND     ximb.end_date_active   >= TRUNC(gd_process_date)
      ;
    --
    -- �W�������R���|�[�l���g�擾�J�[�\��
    CURSOR opmcost_cmpnt_cur(
      pd_apply_date  DATE )
    IS
      SELECT     cclr.calendar_code                                   -- �J�����_�R�[�h
                ,cclr.period_code                                     -- ���ԃR�[�h
                ,ccmv.cost_cmpntcls_id                                -- �����R���|�[�l���gID
                ,ccmv.cost_cmpntcls_code                              -- �����R���|�[�l���g�R�[�h
      FROM       cm_cldr_dtl    cclr                                  -- OPM�����J�����_
                ,cm_cmpt_mst_vl ccmv                                  -- �����R���|�[�l���g
                ,fnd_lookup_values_vl flv                             -- LOOKUP�\
      WHERE      flv.lookup_type          = cv_lookup_cost_cmpt       -- LOOKUP�^�C�v
      AND        flv.enabled_flag         = cv_yes                    -- �g�p�\
      AND        ccmv.cost_cmpntcls_code  = flv.meaning               -- �����R���|�[�l���g�R�[�h
      AND        cclr.start_date         <= pd_apply_date             -- �J�n��
      AND        cclr.end_date           >= pd_apply_date             -- �I����
      ;
    --
    -- *** ���[�J���E���R�[�h ***
    l_parent_item_rec         parent_item_cur%ROWTYPE;                -- �e�i�ڒl�p�����R�[�h
    -- OPM�W�������p
    l_opm_cost_header_rec     xxcmm_004common_pkg.opm_cost_header_rtype;
    l_opm_cost_dist_tab       xxcmm_004common_pkg.opm_cost_dist_ttype;
    --
    -- *** ���[�J�����[�U�[��`��O ***
    ins_err_expt              EXCEPTION;                              -- �f�[�^�o�^�G���[
    concurrent_expt           EXCEPTION;                              -- �R���J�����g���s�G���[
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- A-5 �f�[�^�o�^
    --==============================================================
    lv_step := 'A-5.1';
    -- ������
    l_set_parent_item_rec := NULL;
    --
    IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
      --==============================================================
      -- �e�i�ڂ̏ꍇ�A�ϐ��ɐe�i��(�i�ڈꊇ�o�^�f�[�^)���Z�b�g���܂��B
      --==============================================================
      lv_step := 'A-5.1.1';
      -- �ϐ��ɃZ�b�g
      l_set_parent_item_rec.rate_class               := i_wk_item_rec.rate_class;                   -- ���敪
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete start by Shigeto.Niki
--      l_set_parent_item_rec.palette_max_cs_qty       := TO_NUMBER(i_wk_item_rec.palette_max_cs_qty);     -- �z��
--      l_set_parent_item_rec.palette_max_step_qty     := TO_NUMBER(i_wk_item_rec.palette_max_step_qty);   -- �i��
--      l_set_parent_item_rec.product_class            := TO_NUMBER(i_wk_item_rec.product_class);     -- ���i����
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete end by Shigeto.Niki
      l_set_parent_item_rec.nets                     := TO_NUMBER(i_wk_item_rec.nets);              -- ���e��
      l_set_parent_item_rec.nets_uom_code            := i_etc_rec.nets_uom_code;                    -- ���e�ʒP��
      l_set_parent_item_rec.inc_num                  := TO_NUMBER(i_wk_item_rec.inc_num);           -- �������
      l_set_parent_item_rec.vessel_group             := i_wk_item_rec.vessel_group;                 -- �e��Q
      l_set_parent_item_rec.acnt_group               := i_wk_item_rec.acnt_group;                   -- �o���Q
      l_set_parent_item_rec.acnt_vessel_group        := i_wk_item_rec.acnt_vessel_group;            -- �o���e��Q
      l_set_parent_item_rec.brand_group              := i_wk_item_rec.brand_group;                  -- �u�����h�Q
      -- �{�Џ��i�敪���u2:�h�����N�v�̏ꍇ�A�o�����敪�́u0:���̑��v���Z�b�g���܂��B
      IF ( i_wk_item_rec.hon_product_class = cn_hon_prod_drink ) THEN
        l_set_parent_item_rec.baracha_div              := cn_baracha_etc;                           -- �o�����敪
      ELSE
        l_set_parent_item_rec.baracha_div              := TO_NUMBER(i_wk_item_rec.baracha_div);     -- �o�����敪
      END IF;
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete start by Shigeto.Niki
--      l_set_parent_item_rec.bowl_inc_num             := TO_NUMBER(i_wk_item_rec.bowl_inc_num);      -- �{�[������
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete end by Shigeto.Niki
      l_set_parent_item_rec.case_jan_code            := i_wk_item_rec.case_jan_code;                -- �P�[�XJAN�R�[�h
      l_set_parent_item_rec.sp_supplier_code         := i_wk_item_rec.sp_supplier_code;             -- ���X�d����R�[�h
      l_set_parent_item_rec.case_number              := i_wk_item_rec.case_inc_num;                 -- �P�[�X����(DFF)
      -- NET�͒l�������Ă��Ȃ���Γ��e�ʁ~����������Z�b�g���܂��B
      IF ( i_wk_item_rec.net IS NULL ) THEN
-- Ver1.7  2009/04/10  Add  ��QT1_0219 �Ή�
        IF ( i_etc_rec.nets_uom_code IN ( cn_net_uom_code_kg, cn_net_uom_code_l ) ) THEN
          -- KG, L ���͌W��(1000)��������yNET�� g �̂��߁z
          l_set_parent_item_rec.net := TRUNC(TO_NUMBER(i_wk_item_rec.nets) * TO_NUMBER(i_wk_item_rec.inc_num) * 1000);
        ELSE
          l_set_parent_item_rec.net := TRUNC(TO_NUMBER(i_wk_item_rec.nets) * TO_NUMBER(i_wk_item_rec.inc_num));
        END IF;
-- End
      ELSE
        l_set_parent_item_rec.net := TO_NUMBER( i_wk_item_rec.net );        -- NET
      END IF;
--20090212 Add END
--
-- Ver1.8  2009/05/18 Add  T1_0906 �P�[�X���Z������ǉ�
      -- �P�[�X���Z�����͒l�������Ă��Ȃ���΃P�[�X�������Z�b�g����
      IF ( i_wk_item_rec.case_conv_inc_num IS NULL ) THEN
        l_set_parent_item_rec.case_conv_inc_num := TO_NUMBER( i_wk_item_rec.case_inc_num );
      ELSE
        l_set_parent_item_rec.case_conv_inc_num := i_wk_item_rec.case_conv_inc_num;
      END IF;
-- End
--
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete start by Shigeto.Niki
--      l_set_parent_item_rec.weight_volume            := i_wk_item_rec.weight_volume;                -- �d�ʁ^�̐�(DFF)
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete end by Shigeto.Niki
      l_set_parent_item_rec.jan_code                 := i_wk_item_rec.jan_code;                     -- JAN�R�[�h
      l_set_parent_item_rec.item_um                  := i_wk_item_rec.item_um;                      -- ��P��
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete start by Shigeto.Niki
--      l_set_parent_item_rec.itf_code                 := i_wk_item_rec.itf_code;                     -- ITF�R�[�h
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete end by Shigeto.Niki
      l_set_parent_item_rec.sales_target             := i_wk_item_rec.sales_target_flag;            -- ����Ώۋ敪(DFF)
      --
      -- �J�e�S������validate_item���Ɏ擾�������̂��Z�b�g���܂��B
      l_set_parent_item_rec.ssk_category_id          := i_item_ctg_rec.ssk_category_id;
      l_set_parent_item_rec.ssk_category_set_id      := i_item_ctg_rec.ssk_category_set_id;
      l_set_parent_item_rec.dualum_ind               := i_item_ctg_rec.dualum_ind;
--Ver1.10 2009/06/04 Add start
      IF ( SUBSTRB( i_wk_item_rec.item_code, 1, 1 ) IN ( '5', '6' ) ) THEN
        l_set_parent_item_rec.lot_ctl                := gn_lot_ctl;
      ELSE
        l_set_parent_item_rec.lot_ctl                := i_item_ctg_rec.lot_ctl;
      END IF;
--Ver1.10 End
      l_set_parent_item_rec.autolot_active_indicator := i_item_ctg_rec.autolot_active_indicator;
      l_set_parent_item_rec.lot_suffix               := i_item_ctg_rec.lot_suffix;
      l_set_parent_item_rec.hsk_category_id          := i_item_ctg_rec.hsk_category_id;
      l_set_parent_item_rec.hsk_category_set_id      := i_item_ctg_rec.hsk_category_set_id;
    ELSE
      --==============================================================
      -- �q�i�ڂ̏ꍇ�A�e�i�ڒ��o���A�ϐ��ɃZ�b�g���܂��B
      --==============================================================
      lv_step := 'A-5.1.2';
      SELECT  ximb.parent_item_id
      INTO    ln_parent_item_id
      FROM    xxcmn_item_mst_b  ximb
             ,ic_item_mst_b     iimb
      WHERE   ximb.parent_item_id     = iimb.item_id
      AND     iimb.item_no            = i_wk_item_rec.parent_item_code
      AND     ximb.item_id            = ximb.parent_item_id
      AND     ximb.start_date_active <= TRUNC(gd_process_date)
      AND     ximb.end_date_active   >= TRUNC(gd_process_date)
      ;
      -- ������
      l_parent_item_rec := NULL;
      OPEN parent_item_cur(
             pn_parent_item_id => ln_parent_item_id
           );
      FETCH parent_item_cur INTO l_parent_item_rec;
      CLOSE parent_item_cur;
      --
      -- �ϐ��ɃZ�b�g
      l_set_parent_item_rec := l_parent_item_rec;
      --
      -- �q�i�ڂŏ��i���i�敪(�e�i�ڒl)���u1:���i�v�̏ꍇ�A���X�d����R�[�h�͐e�i�ڒl���Z�b�g
      -- ����ȊO�͕i�ڈꊇ�o�^���[�N���Z�b�g
      IF ( TO_NUMBER(l_set_parent_item_rec.item_product_class) <> cn_item_prod_item ) THEN
        l_set_parent_item_rec.sp_supplier_code := i_wk_item_rec.sp_supplier_code;
      END IF;
    END IF;
    --
    --==============================================================
    -- A-5.2 OPM�i�ړo�^����
    --==============================================================
    lv_step := 'A-5.2';
    -- ���R�����g�ɂ��Ă�����͓̂��ɗv�����Ȃ�����
    -- ���Œ�l�ݒ�͕W����ʂŏ����l�ƂȂ��Ă��鍀��(NOT NULL)
    -- ������
    l_opm_item_rec := NULL;
    --
    -- GET ic_item_mst_b.item_id SEQUENCE
    SELECT gem5_item_id_s.NEXTVAL
    INTO   ln_item_id
    FROM   DUAL;
    --
    -- �e�i�ڂ̏ꍇ�e�i��ID�ɕi��ID���Z�b�g���܂��B
    IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
      ln_parent_item_id := ln_item_id;
    END IF;
    --
    l_opm_item_rec.item_id                  := ln_item_id;                                          -- �i��ID
    l_opm_item_rec.item_no                  := i_wk_item_rec.item_code;                             -- �i�ڃR�[�h
    l_opm_item_rec.item_desc1               := i_wk_item_rec.item_name;                             -- �E�v
--    l_opm_item_rec.item_desc2               := NULL;                                                -- ����
--    l_opm_item_rec.alt_itema                := NULL;                                                -- ��֕i��A
--    l_opm_item_rec.alt_itemb                := NULL;                                                -- ��֕i��B
    l_opm_item_rec.item_um                  := l_set_parent_item_rec.item_um;                       -- ��P��
    l_opm_item_rec.dualum_ind               := l_set_parent_item_rec.dualum_ind;                    -- ��d�Ǘ�(�q�i�ڂ̏ꍇ�A�e�l�p������)
--    l_opm_item_rec.item_um2                 := NULL;                                                -- �P�ʓ�d
    l_opm_item_rec.deviation_lo             := 0;                                                   -- �΍��W��-
    l_opm_item_rec.deviation_hi             := 0;                                                   -- �΍��W��+
--    l_opm_item_rec.level_code               := NULL;                                                --
--Ver1.10 2009/06/04 Add start
    --l_opm_item_rec.lot_ctl                  := l_set_parent_item_rec.lot_ctl;                       -- ���b�g(�q�i�ڂ̏ꍇ�A�e�l�p������)
      IF ( SUBSTRB( i_wk_item_rec.item_code, 1, 1 ) IN ( '5', '6' ) ) THEN
        l_opm_item_rec.lot_ctl              := gn_lot_ctl;
      ELSE
        l_opm_item_rec.lot_ctl              := l_set_parent_item_rec.lot_ctl;                       -- ���b�g(�q�i�ڂ̏ꍇ�A�e�l�p������)
      END IF;
--Ver1.10 End
    l_opm_item_rec.lot_indivisible          := 0;                                                   -- �����s��
    l_opm_item_rec.sublot_ctl               := 0;                                                   -- �T�u���b�g
-- Ver1.8  2009/05/18 Mod  T1_0737 �ۊǏꏊ�� 1:���؍ς� ��ݒ�
--    l_opm_item_rec.loct_ctl                 := 0;                                                   -- �ۊǏꏊ
    l_opm_item_rec.loct_ctl                 := 1;                                                   -- �ۊǏꏊ
-- End
    l_opm_item_rec.noninv_ind               := 0;                                                   -- ��݌�
    l_opm_item_rec.match_type               := 3;                                                   -- �ƍ�
    l_opm_item_rec.inactive_ind             := 0;                                                   -- �����敪
--    l_opm_item_rec.inv_type                 := NULL;                                                -- �R�[�h.�^�C�v
    l_opm_item_rec.shelf_life               := 0;                                                   -- �ۑ�����
    l_opm_item_rec.retest_interval          := 0;                                                   -- �ăe�X�g�Ԋu
--    l_opm_item_rec.gl_class                 := NULL;                                                -- GL
--    l_opm_item_rec.inv_class                := NULL;                                                -- �݌�
--    l_opm_item_rec.sales_class              := NULL;                                                -- ����
--    l_opm_item_rec.ship_class               := NULL;                                                -- �o��
--    l_opm_item_rec.frt_class                := NULL;                                                -- �^����
--    l_opm_item_rec.price_class              := NULL;                                                -- ���i
--    l_opm_item_rec.storage_class            := NULL;                                                -- �i�[
--    l_opm_item_rec.purch_class              := NULL;                                                -- �w��
--    l_opm_item_rec.tax_class                := NULL;                                                --
--    l_opm_item_rec.customs_class            := NULL;                                                -- �ʊ�
--    l_opm_item_rec.alloc_class              := NULL;                                                -- ����
--    l_opm_item_rec.planning_class           := NULL;                                                -- �v��
--    l_opm_item_rec.itemcost_class           := NULL;                                                -- ����
--    l_opm_item_rec.cost_mthd_code           := NULL;                                                -- �����Q��
--    l_opm_item_rec.upc_code                 := NULL;                                                -- UPC�R�[�h
    l_opm_item_rec.grade_ctl                := 0;                                                   -- �O���[�h
    l_opm_item_rec.status_ctl               := 0;                                                   -- �X�e�[�^�X
--    l_opm_item_rec.qc_grade                 := NULL;                                                -- �O���[�h�f�t�H���g
--    l_opm_item_rec.lot_status               := NULL;                                                -- ���b�g�X�e�[�^�X
--    l_opm_item_rec.bulk_id                  := NULL;                                                --
--    l_opm_item_rec.pkg_id                   := NULL;                                                --
--    l_opm_item_rec.qcitem_id                := NULL;                                                --
--    l_opm_item_rec.qchold_res_code          := NULL;                                                --
--    l_opm_item_rec.expaction_code           := NULL;                                                --
    l_opm_item_rec.fill_qty                 := 0;                                                   --
--    l_opm_item_rec.fill_um                  := NULL;                                                --
    l_opm_item_rec.expaction_interval       := 0;                                                   --
    l_opm_item_rec.phantom_type             := 0;                                                   --
    l_opm_item_rec.whse_item_id             := l_opm_item_rec.item_id;                              --
    l_opm_item_rec.experimental_ind         := 0;                                                   -- ����
    l_opm_item_rec.exported_date            := gd_process_date;                                     --
--    l_opm_item_rec.trans_cnt                := NULL;                                                --
    l_opm_item_rec.delete_mark              := 0;                                                     --
--    l_opm_item_rec.text_code                := NULL;                                                --
--    l_opm_item_rec.seq_dpnd_class           := NULL;                                                -- ���i
--    l_opm_item_rec.commodity_code           := NULL;                                                -- ���i
    l_opm_item_rec.creation_date            := cd_creation_date;                                    -- �쐬��
    l_opm_item_rec.created_by               := cn_created_by;                                       -- �쐬��
    l_opm_item_rec.last_update_date         := cd_last_update_date;                                 -- �ŏI�X�V��
    l_opm_item_rec.last_updated_by          := cn_last_updated_by;                                  -- �ŏI�X�V��
    l_opm_item_rec.last_update_login        := cn_last_update_login;                                -- �ŏI�X�V���O�C��ID
    l_opm_item_rec.program_application_id   := cn_program_application_id;                           -- �R���J�����g�E�v���O�����̃A�v���P�[�V����
    l_opm_item_rec.program_id               := cn_program_id;                                       -- �R���J�����g�E�v���O����ID
    l_opm_item_rec.program_update_date      := cd_program_update_date;                              -- �v���O�����ɂ��X�V��
    l_opm_item_rec.request_id               := cn_request_id;                                       -- �v��ID
    -- ����Q�͎q�i�ڂ̏ꍇ�̂݃Z�b�g���܂��B
--    -- ���e�i�ڂ͕ύX�\��K�p�Ŕ��f����܂��B
--    IF ( i_wk_item_rec.item_code <> i_wk_item_rec.parent_item_code ) THEN
--      l_opm_item_rec.attribute1               := NULL;                                              -- ���E�Q����
--      l_opm_item_rec.attribute2               := i_wk_item_rec.policy_group;                        -- �V�E�Q����
--      l_opm_item_rec.attribute3               := TO_CHAR(gd_process_date, cv_date_format_rmd);      -- �Q���ޓK�p�J�n��
--    END IF;
--    l_opm_item_rec.attribute4               := NULL;                                                -- ���E�艿
--    l_opm_item_rec.attribute5               := NULL;                                                -- �V�E�艿
--    l_opm_item_rec.attribute6               := NULL;                                                -- �艿�K�p�J�n��
--    l_opm_item_rec.attribute7               := NULL;                                                -- ���E�c�ƌ���
--    l_opm_item_rec.attribute8               := NULL;                                                -- �V�E�c�ƌ���
--    l_opm_item_rec.attribute9               := NULL;                                                -- �c�ƌ����K�p�J�n��
--    l_opm_item_rec.attribute10              := NULL;                                                -- �d�ʗe�ϋ敪
--
--��2009/03/13 Add Start
--    l_opm_item_rec.attribute10              := l_set_parent_item_rec.weight_volume_class;             -- �d�ʗe�ϋ敪
--��Add End
--��2009/03/13 Add Start
      -- �{�Џ��i�敪���u1:���[�t�v�̏ꍇ�A�d�ʗe�ϋ敪�́u2:�e�ρv
      --               �u2:�h�����N�v�̏ꍇ�A�d�ʗe�ϋ敪�́u1:�d�ʁv
      IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
        IF ( i_wk_item_rec.hon_product_class = cn_hon_prod_leaf ) THEN
          l_opm_item_rec.attribute10          := cv_volume;                                           -- �d�ʗe�ϋ敪(DFF)
        ELSIF ( i_wk_item_rec.hon_product_class = cn_hon_prod_drink ) THEN
          l_opm_item_rec.attribute10          := cv_weight;                                           -- �d�ʗe�ϋ敪(DFF)
        END IF;
      ELSE
        l_opm_item_rec.attribute10          := l_set_parent_item_rec.weight_volume_class;
      END IF;
--��Add End
    l_opm_item_rec.attribute11              := l_set_parent_item_rec.case_number;                   -- �P�[�X����(�q�i�ڂ̏ꍇ�A�e�l�p������)
    l_opm_item_rec.attribute12              := l_set_parent_item_rec.net;                           -- NET(�q�i�ڂ̏ꍇ�A�e�l�p������)
    l_opm_item_rec.attribute13              := i_wk_item_rec.sale_start_date;                         -- �����i�����j�J�n��
-- 2009/09/07 Ver1.15 ��Q0001258 modify start by Y.Kuboshima
--    l_opm_item_rec.attribute14              := NULL;                                                -- ����L/T
--    l_opm_item_rec.attribute15              := NULL;                                                -- �����Ǘ��敪
    l_opm_item_rec.attribute14              := '0';                                                 -- ����L/T
    l_opm_item_rec.attribute15              := '1';                                                 -- �����Ǘ��敪
-- 2009/09/07 Ver1.15 ��Q0001258 modify end by Y.Kuboshima
--    l_opm_item_rec.attribute16              := NULL;                                                -- �e��
--
--��2009/03/13 Add Start
    IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
      IF ( i_wk_item_rec.hon_product_class = cn_hon_prod_leaf ) THEN
        l_opm_item_rec.attribute16              := i_wk_item_rec.weight_volume;
      ELSE
-- 2009/06/04 Ver1.10 ��QT1_1319 Add start
      --l_opm_item_rec.attribute16              := NULL;
        l_opm_item_rec.attribute16              := '0';
      END IF;
    ELSE
      IF ( l_set_parent_item_rec.weight_volume_class = cv_volume ) THEN
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 modify start by Shigeto.Niki
--        l_opm_item_rec.attribute16              :=l_set_parent_item_rec.weight_volume;
        l_opm_item_rec.attribute16              := i_wk_item_rec.weight_volume;
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 modify end by Shigeto.Niki
      ELSE
        l_opm_item_rec.attribute16              := '0';
      END IF;
-- 2009/06/04 Ver1.10 ��QT1_1319 End
    END IF;                                                                                          -- �e��
--��Add End
-- 2009/09/07 Ver1.15 ��Q0001258 modify start by Y.Kuboshima
--    l_opm_item_rec.attribute17              := NULL;                                                -- ��\����
    l_opm_item_rec.attribute17              := '1';                                                 -- ��\����
-- 2009/09/07 Ver1.15 ��Q0001258 modify end by Y.Kuboshima
-- Ver1.8  2009/05/18 Mod  T1_0318 �o�׋敪�� 1:�o�׉� ��ݒ�
--    l_opm_item_rec.attribute18              := NULL;                                                -- �o�׋敪
    l_opm_item_rec.attribute18              := '1';                                                 -- �o�׋敪
-- End
--    l_opm_item_rec.attribute19              := NULL;                                                -- �|
-- 2009/09/07 Ver1.15 ��Q0001258 modify start by Y.Kuboshima
--    l_opm_item_rec.attribute20              := NULL;                                                -- �d���P�����o���^�C�v
    l_opm_item_rec.attribute20              := '2';                                                 -- �d���P�����o���^�C�v
-- 2009/09/07 Ver1.15 ��Q0001258 modify end by Y.Kuboshima
    l_opm_item_rec.attribute21              := l_set_parent_item_rec.jan_code;                      -- JAN�R�[�h(�q�i�ڂ̏ꍇ�A�e�l�p������)
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 modify start by Shigeto.Niki
--    l_opm_item_rec.attribute22              := l_set_parent_item_rec.itf_code;                      -- ITF�R�[�h(�q�i�ڂ̏ꍇ�A�e�l�p������)
    l_opm_item_rec.attribute22              := i_wk_item_rec.itf_code;                                -- ITF�R�[�h
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 modify end by Shigeto.Niki
--    l_opm_item_rec.attribute23              := NULL;                                                -- �����L���敪
--��2009/03/17 Add Start
    IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
      IF ( ( i_wk_item_rec.item_product_class = cn_item_prod_prod )
        AND ( i_wk_item_rec.hon_product_class = cn_hon_prod_drink) ) THEN
        l_opm_item_rec.attribute23              := cv_exam_class_1;                                   -- �����L���敪
      ELSE
        l_opm_item_rec.attribute23              := cv_exam_class_0;                                   -- �����L���敪
      END IF;
    ELSE
      IF ( ( l_set_parent_item_rec.item_product_class = cn_item_prod_prod )
        AND ( l_set_parent_item_rec.hon_product_class = cn_hon_prod_drink) ) THEN
        l_opm_item_rec.attribute23              := cv_exam_class_1;                                   -- �����L���敪
      ELSE
        l_opm_item_rec.attribute23              := cv_exam_class_0;                                   -- �����L���敪
      END IF;
    END IF;
-- Add End
--    l_opm_item_rec.attribute24              := NULL;                                                -- ���o�Ɋ��Z�P��
--    l_opm_item_rec.attribute25              := l_set_parent_item_rec.weight_volume;                 -- �d��(�q�i�ڂ̏ꍇ�A�e�l�p������)
--��2009/03/13 Add Start
    IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
      IF ( i_wk_item_rec.hon_product_class = cn_hon_prod_drink ) THEN
        l_opm_item_rec.attribute25              := i_wk_item_rec.weight_volume;
      ELSE
-- 2009/06/04 Ver1.10 ��QT1_1319 Add start
      --l_opm_item_rec.attribute25              := NULL;
        l_opm_item_rec.attribute25              := '0';
      END IF;
    ELSE
      IF ( l_set_parent_item_rec.weight_volume_class = cv_weight ) THEN
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 modify start by Shigeto.Niki
--        l_opm_item_rec.attribute25              :=l_set_parent_item_rec.weight_volume;
        l_opm_item_rec.attribute25              := i_wk_item_rec.weight_volume;
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 modify end by Shigeto.Niki
      ELSE
        l_opm_item_rec.attribute25              := '0';
      END IF;
-- 2009/06/04 Ver1.10 ��QT1_1319 End
    END IF;                                                                                           -- �d��(�q�i�ڂ̏ꍇ�A�e�l�p������)
--��Add End
    l_opm_item_rec.attribute26              := l_set_parent_item_rec.sales_target;                  -- ����Ώۋ敪(�q�i�ڂ̏ꍇ�A�e�l�p������)
-- 2009/09/07 Ver1.15 ��Q0001258 modify start by Y.Kuboshima
--    l_opm_item_rec.attribute27              := NULL;                                                -- �����
--    l_opm_item_rec.attribute28              := NULL;                                                -- �d���敪
--    l_opm_item_rec.attribute29              := NULL;                                                -- �����\�����
    l_opm_item_rec.attribute27              := '0';                                                   -- �����
    l_opm_item_rec.attribute28              := '1';                                                   -- �d���敪
    l_opm_item_rec.attribute29              := '0';                                                   -- �����\�����
-- 2009/09/07 Ver1.15 ��Q0001258 modify end by Y.Kuboshima
--    l_opm_item_rec.attribute30              := NULL;                                                -- �}�X�^��M����
--��2009/03/17 Add Start
    l_opm_item_rec.attribute30              := TO_CHAR( SYSDATE, cv_date_fmt_std );                   -- �}�X�^��M����
--��Add End
--    l_opm_item_rec.attribute_category       := NULL;                                                --
--    l_opm_item_rec.item_abccode             := NULL;                                                -- ABC�����N
-- Ver1.8  2009/05/18 Mod  T1_0737 ���i�ݒ�\�[�X�� 0:�I�[�_�[ ��ݒ�
--    l_opm_item_rec.ont_pricing_qty_source   := NULL;                                                -- ���i�ݒ�\�[�X
    l_opm_item_rec.ont_pricing_qty_source   := 0;                                                   -- ���i�ݒ�\�[�X
-- End
--    l_opm_item_rec.alloc_category_id        := NULL;                                                -- �����J�e�S��ID
--    Z.customs_category_id      := NULL;                                                -- �J�X�^���E�J�e�S��ID
--    l_opm_item_rec.frt_category_id          := NULL;                                                -- �^���J�e�S��ID
--    l_opm_item_rec.gl_category_id           := NULL;                                                -- GL�J�e�S��ID
--    l_opm_item_rec.inv_category_id          := NULL;                                                -- �݌ɃJ�e�S��ID
--    l_opm_item_rec.cost_category_id         := NULL;                                                -- �����J�e�S��ID
--    l_opm_item_rec.planning_category_id     := NULL;                                                -- �v��J�e�S��ID
--    l_opm_item_rec.price_category_id        := NULL;                                                -- ���i�J�e�S��ID
--    l_opm_item_rec.purch_category_id        := NULL;                                                -- �w���J�e�S��ID
--    l_opm_item_rec.sales_category_id        := NULL;                                                -- ����J�e�S��ID
--    l_opm_item_rec.seq_category_id          := NULL;                                                -- �����J�e�S��ID
--    l_opm_item_rec.ship_category_id         := NULL;                                                -- �o�׃J�e�S��ID
--    l_opm_item_rec.storage_category_id      := NULL;                                                -- �i�[�J�e�S��ID
--    l_opm_item_rec.tax_category_id          := NULL;                                                -- �ŋ��J�e�S��ID
    l_opm_item_rec.autolot_active_indicator := l_set_parent_item_rec.autolot_active_indicator;      -- �������b�g�̔ԗL��(�q�i�ڂ̏ꍇ�A�e�l�p������)
--    l_opm_item_rec.lot_prefix               := NULL;                                                -- ���b�g�E�v���t�B�b�N�X
    l_opm_item_rec.lot_suffix               := l_set_parent_item_rec.lot_suffix;                    -- ���b�g�E�T�t�B�b�N�X(�q�i�ڂ̏ꍇ�A�e�l�p������)
--    l_opm_item_rec.sublot_prefix            := NULL;                                                -- �T�u���b�g�E�v���t�B�b�N�X
--    l_opm_item_rec.sublot_suffix            := NULL;                                                -- �T�u���b�g�E�T�t�B�b�N�X
    --
    -- OPM�i�ړo�^
    xxcmm_004common_pkg.ins_opm_item(
      i_opm_item_rec => l_opm_item_rec
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_iimb;
      RAISE ins_err_expt;     -- �f�[�^�o�^��O
    END IF;
    --
    --==============================================================
    -- A-5.3 OPM�i�ڃA�h�I���o�^����
    --==============================================================
    lv_step := 'A-5.3';
-- 2009/09/07 Ver1.15 ��Q0001258 add start by Y.Kuboshima
    -- OPM�i�ڃA�h�I���ɐݒ肷�鍀�ڂ̒ǉ�
    l_xxcmn_item_rec.model_type               := 50;                                                -- �^���
    l_xxcmn_item_rec.product_type             := 1;                                                 -- ���i���
    l_xxcmn_item_rec.expiration_day           := 0;                                                 -- �ܖ�����
    l_xxcmn_item_rec.delivery_lead_time       := 0;                                                 -- �[������
    l_xxcmn_item_rec.whse_county_code         := gv_fact_pg;                                        -- �H��Q�R�[�h
    l_xxcmn_item_rec.standard_yield           := 0;                                                 -- �W������
    l_xxcmn_item_rec.shelf_life               := 0;                                                 -- �������
    l_xxcmn_item_rec.shelf_life_class         := '10';                                              -- �ܖ����ԋ敪
    l_xxcmn_item_rec.bottle_class             := '10';                                              -- �e��敪
    l_xxcmn_item_rec.uom_class                := '10';                                              -- �P�ʋ敪
    l_xxcmn_item_rec.inventory_chk_class      := '10';                                              -- �I���敪
    l_xxcmn_item_rec.trace_class              := '10';                                              -- �g���[�X�敪
    l_xxcmn_item_rec.cs_weigth_or_capacity    := 1;                                                 -- �P�[�X�d�ʗe��
    l_xxcmn_item_rec.raw_material_consumption := 1;                                                 -- �����g�p��
-- 2009/09/07 Ver1.15 ��Q0001258 add end by Y.Kuboshima
    BEGIN
      INSERT INTO xxcmn_item_mst_b(
        item_id
       ,start_date_active
       ,end_date_active
       ,active_flag
       ,item_name
       ,item_short_name
       ,item_name_alt
       ,parent_item_id
       ,obsolete_class
       ,obsolete_date
       ,model_type
       ,product_class
       ,product_type
       ,expiration_day
       ,delivery_lead_time
       ,whse_county_code
       ,standard_yield
       ,shipping_end_date
       ,rate_class
       ,shelf_life
       ,shelf_life_class
       ,bottle_class
       ,uom_class
       ,inventory_chk_class
       ,trace_class
       ,shipping_cs_unit_qty
       ,palette_max_cs_qty
       ,palette_max_step_qty
       ,palette_step_qty
       ,cs_weigth_or_capacity
       ,raw_material_consumption
       ,attribute1
       ,attribute2
       ,attribute3
       ,attribute4
       ,attribute5
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
        ln_item_id                                          -- �i��ID
-- Ver1.7  2009/04/10  Mod  ��QT1_0437 �Ή�
--       ,gd_process_date                                     -- �K�p�J�n��
-- Ver1.13 2009/07/24 Mod Start
--       ,TRUNC( SYSDATE )                                    -- �K�p�J�n��
       ,gd_opm_apply_date                                   -- �K�p�J�n��
-- End
-- Ver1.13 End
       ,TO_DATE(cv_max_date, cv_date_fmt_std)               -- �K�p�I����
     --2009/03/16  �K�p�σt���O�̏����l���uY�v�ɕύX�������߃R�����g�A�E�g
     --,cv_no                                               -- �K�p�σt���O
       ,cv_yes                                              -- �K�p�σt���O  2009/03/16 �ύX
       ,i_wk_item_rec.item_name                             -- ������
       ,i_wk_item_rec.item_short_name                       -- ����
       ,i_wk_item_rec.item_name_alt                         -- �J�i��
       ,ln_parent_item_id                                   -- �e�i��ID
       ,NULL                                                -- �p�~�敪
       ,NULL                                                -- �p�~���i�������~���j
-- 2009/09/07 Ver1.15 ��Q0001258 modify start by Y.Kuboshima
--       ,NULL                                                -- �^���
       ,l_xxcmn_item_rec.model_type                         -- �^���
-- 2009/09/07 Ver1.15 ��Q0001258 modify end by Y.Kuboshima
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 modify start by Shigeto.Niki
--       ,l_set_parent_item_rec.product_class                 -- ���i����(�q�i�ڂ̏ꍇ�A�e�l�p������)
       ,i_wk_item_rec.product_class                         -- ���i���� 
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 modify end by Shigeto.Niki
-- 2009/09/07 Ver1.15 ��Q0001258 modify start by Y.Kuboshima
--       ,NULL                                                -- ���i���
--       ,NULL                                                -- �ܖ�����
--       ,NULL                                                -- �[������
--       ,NULL                                                -- �H��Q�R�[�h
--       ,NULL                                                -- �W������
       ,l_xxcmn_item_rec.product_type                       -- ���i���
       ,l_xxcmn_item_rec.expiration_day                     -- �ܖ�����
       ,l_xxcmn_item_rec.delivery_lead_time                 -- �[������
       ,l_xxcmn_item_rec.whse_county_code                   -- �H��Q�R�[�h
       ,l_xxcmn_item_rec.standard_yield                     -- �W������
-- 2009/09/07 Ver1.15 ��Q0001258 modify end by Y.Kuboshima
       ,NULL                                                -- �o�ג�~��
       ,l_set_parent_item_rec.rate_class                    -- ���敪(�q�i�ڂ̏ꍇ�A�e�l�p������)
-- 2009/09/07 Ver1.15 ��Q0001258 modify start by Y.Kuboshima
--       ,NULL                                                -- �������
--       ,NULL                                                -- �ܖ����ԋ敪
--       ,NULL                                                -- �e��敪
--       ,NULL                                                -- �P�ʋ敪
--       ,NULL                                                -- �I���敪
--       ,NULL                                                -- �g���[�X�敪
       ,l_xxcmn_item_rec.shelf_life                         -- �������
       ,l_xxcmn_item_rec.shelf_life_class                   -- �ܖ����ԋ敪
       ,l_xxcmn_item_rec.bottle_class                       -- �e��敪
       ,l_xxcmn_item_rec.uom_class                          -- �P�ʋ敪
       ,l_xxcmn_item_rec.inventory_chk_class                -- �I���敪
       ,l_xxcmn_item_rec.trace_class                        -- �g���[�X�敪
-- 2009/09/07 Ver1.15 ��Q0001258 modify end by Y.Kuboshima
       ,NULL                                                -- �o�ד���
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 modify start by Shigeto.Niki
--       ,l_set_parent_item_rec.palette_max_cs_qty            -- �z��(�q�i�ڂ̏ꍇ�A�e�l�p������)
--       ,l_set_parent_item_rec.palette_max_step_qty          -- �p���b�g����ő�i��(�q�i�ڂ̏ꍇ�A�e�l�p������)
       ,i_wk_item_rec.palette_max_cs_qty                    -- �z��
       ,i_wk_item_rec.palette_max_step_qty                  -- �p���b�g����ő�i��
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 modify end by Shigeto.Niki
       ,NULL                                                -- �p���b�g�i
-- 2009/09/07 Ver1.15 ��Q0001258 modify start by Y.Kuboshima
--       ,NULL                                                -- �P�[�X�d�ʗe��
--       ,NULL                                                -- �����g�p��
       ,l_xxcmn_item_rec.cs_weigth_or_capacity              -- �P�[�X�d�ʗe��
       ,l_xxcmn_item_rec.raw_material_consumption           -- �����g�p��
-- 2009/09/07 Ver1.15 ��Q0001258 modify end by Y.Kuboshima
       ,NULL                                                -- �\���P
       ,NULL                                                -- �\���Q
       ,NULL                                                -- �\���R
       ,NULL                                                -- �\���S
       ,NULL                                                -- �\���T
       ,cn_created_by                                       -- �쐬��
       ,cd_creation_date                                    -- �쐬��
       ,cn_last_updated_by                                  -- �ŏI�X�V��
       ,cd_last_update_date                                 -- �ŏI�X�V��
       ,cn_last_update_login                                -- �ŏI�X�V���O�C��
       ,cn_request_id                                       -- �v��ID
       ,cn_program_application_id                           -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
       ,cn_program_id                                       -- �R���J�����g�E�v���O����ID
       ,cd_program_update_date                              -- �v���O�����ɂ��X�V��
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf    := SQLERRM;
        lv_tkn_table := cv_table_ximb;
        RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END;
    --
    --==============================================================
    -- A-5.4 OPM�i�ڃJ�e�S������(���i���i�敪)�o�^����
    --==============================================================
    lv_step := 'A-5.4';
    l_ctg_product_prod_rec.item_id         := ln_item_id;
    l_ctg_product_prod_rec.category_set_id := l_set_parent_item_rec.ssk_category_set_id;  -- (�q�i�ڂ̏ꍇ�A�e�l�p������)
    l_ctg_product_prod_rec.category_id     := l_set_parent_item_rec.ssk_category_id;      -- (�q�i�ڂ̏ꍇ�A�e�l�p������)
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_ctg_product_prod_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_gic_ssk;
      RAISE ins_err_expt;     -- �f�[�^�o�^��O
    END IF;
    --
    --==============================================================
    -- A-5.5 OPM�i�ڃJ�e�S������(�{�Џ��i�敪)�o�^����
    --==============================================================
    lv_step := 'A-5.5';
    l_ctg_hon_prod_rec.item_id         := ln_item_id;
    l_ctg_hon_prod_rec.category_set_id := l_set_parent_item_rec.hsk_category_set_id;      -- (�q�i�ڂ̏ꍇ�A�e�l�p������)
    l_ctg_hon_prod_rec.category_id     := l_set_parent_item_rec.hsk_category_id;          -- (�q�i�ڂ̏ꍇ�A�e�l�p������)
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_ctg_hon_prod_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_gic_hsk;
      RAISE ins_err_expt;     -- �f�[�^�o�^��O
    END IF;
    --
    --
    --==============================================================
    -- A-5.6 OPM�i�ڃJ�e�S������(����Q)�o�^����
    -- �q�i�ڂ̏ꍇ�̂ݍ쐬���܂��B
    --==============================================================
    lv_step := 'A-5.6';
    IF ( i_wk_item_rec.item_code <> i_wk_item_rec.parent_item_code ) THEN
      l_ctg_hon_prod_rec.item_id         := ln_item_id;
      l_ctg_hon_prod_rec.category_set_id := l_set_parent_item_rec.sg_category_set_id;     -- (�q�i�ڂ̏ꍇ�A�e�l�p������)
      l_ctg_hon_prod_rec.category_id     := l_set_parent_item_rec.sg_category_id;         -- (�q�i�ڂ̏ꍇ�A�e�l�p������)
      xxcmm_004common_pkg.proc_opmitem_categ_ref(
        i_item_category_rec => l_ctg_hon_prod_rec
       ,ov_errbuf           => lv_errbuf
       ,ov_retcode          => lv_retcode
       ,ov_errmsg           => lv_errmsg
      );
      -- �������ʃ`�F�b�N
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_tkn_table := cv_table_gic_sg;
        RAISE ins_err_expt;   -- �f�[�^�o�^��O
      END IF;
    END IF;
    --
--Ver1.11  2009/06/11 Add start
    --==============================================================
    -- A-5.6-1 OPM�i�ڃJ�e�S������(�o�����敪)�o�^����
    --==============================================================
    lv_step := 'A-5.6-1';
    l_ctg_hon_prod_rec.item_id         := ln_item_id;
    l_ctg_hon_prod_rec.category_set_id := i_item_ctg_rec.bd_category_set_id;     -- (�q�i�ڂ̏ꍇ�A�e�l�p������)
    l_ctg_hon_prod_rec.category_id     := i_item_ctg_rec.bd_category_id;         -- (�q�i�ڂ̏ꍇ�A�e�l�p������)
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_ctg_hon_prod_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_gic_bd;
      RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END IF;
    --
    --==============================================================
    -- A-5.6-2 OPM�i�ڃJ�e�S������(�}�[�P�p�Q�R�[�h)�o�^����
    --==============================================================
    lv_step := 'A-5.6-2';
    l_ctg_hon_prod_rec.item_id         := ln_item_id;
    l_ctg_hon_prod_rec.category_set_id := i_item_ctg_rec.mgc_category_set_id;     -- (�q�i�ڂ̏ꍇ�A�e�l�p������)
    l_ctg_hon_prod_rec.category_id     := i_item_ctg_rec.mgc_category_id;         -- (�q�i�ڂ̏ꍇ�A�e�l�p������)
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_ctg_hon_prod_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_gic_mgc;
      RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END IF;
    --
    --==============================================================
    -- A-5.6-3 OPM�i�ڃJ�e�S������(�Q�R�[�h)�o�^����
    -- �e�i�ڂ̏ꍇ�A����Q�R�[�h���K�p���ꂽ���ɐݒ肳���
    --==============================================================
    lv_step := 'A-5.6-3';
    IF ( i_wk_item_rec.item_code <> i_wk_item_rec.parent_item_code ) THEN
      l_ctg_hon_prod_rec.item_id         := ln_item_id;
      l_ctg_hon_prod_rec.category_set_id := i_item_ctg_rec.pg_category_set_id;     -- (�q�i�ڂ̏ꍇ�A�e�l�p������)
      l_ctg_hon_prod_rec.category_id     := i_item_ctg_rec.pg_category_id;         -- (�q�i�ڂ̏ꍇ�A�e�l�p������)
      --
      xxcmm_004common_pkg.proc_opmitem_categ_ref(
        i_item_category_rec => l_ctg_hon_prod_rec
       ,ov_errbuf           => lv_errbuf
       ,ov_retcode          => lv_retcode
       ,ov_errmsg           => lv_errmsg
      );
      -- �������ʃ`�F�b�N
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_tkn_table := cv_table_gic_pg;
        RAISE ins_err_expt;   -- �f�[�^�o�^��O
      END IF;
    END IF;
--Ver1.11  2009/06/11 End
--
-- 2009/09/07 Ver1.15 ��Q0001258 add start by Y.Kuboshima
    --
    --==============================================================
    -- A-5.6-4 OPM�i�ڃJ�e�S������(�i�ڋ敪)�o�^����
    --==============================================================
    lv_step := 'A-5.6-4';
    l_ctg_hon_prod_rec.item_id         := ln_item_id;
    l_ctg_hon_prod_rec.category_set_id := i_item_ctg_rec.itd_category_set_id;
    l_ctg_hon_prod_rec.category_id     := i_item_ctg_rec.itd_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_ctg_hon_prod_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_gic_itd;
      RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END IF;
    --
    --==============================================================
    -- A-5.6-5 OPM�i�ڃJ�e�S������(���O�敪)�o�^����
    --==============================================================
    lv_step := 'A-5.6-5';
    l_ctg_hon_prod_rec.item_id         := ln_item_id;
    l_ctg_hon_prod_rec.category_set_id := i_item_ctg_rec.ind_category_set_id;
    l_ctg_hon_prod_rec.category_id     := i_item_ctg_rec.ind_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_ctg_hon_prod_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_gic_ind;
      RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END IF;
    --
    --==============================================================
    -- A-5.6-6 OPM�i�ڃJ�e�S������(���i�敪)�o�^����
    --==============================================================
    lv_step := 'A-5.6-6';
    l_ctg_hon_prod_rec.item_id         := ln_item_id;
    l_ctg_hon_prod_rec.category_set_id := i_item_ctg_rec.pd_category_set_id;
    l_ctg_hon_prod_rec.category_id     := i_item_ctg_rec.pd_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_ctg_hon_prod_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_gic_pd;
      RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END IF;
    --
    --==============================================================
    -- A-5.6-7 OPM�i�ڃJ�e�S������(�i���敪)�o�^����
    --==============================================================
    lv_step := 'A-5.6-7';
    l_ctg_hon_prod_rec.item_id         := ln_item_id;
    l_ctg_hon_prod_rec.category_set_id := i_item_ctg_rec.qd_category_set_id;
    l_ctg_hon_prod_rec.category_id     := i_item_ctg_rec.qd_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_ctg_hon_prod_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_gic_qd;
      RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END IF;
    --
    --==============================================================
    -- A-5.6-8 OPM�i�ڃJ�e�S������(�H��Q�R�[�h)�o�^����
    --==============================================================
    lv_step := 'A-5.6-8';
    l_ctg_hon_prod_rec.item_id         := ln_item_id;
    l_ctg_hon_prod_rec.category_set_id := i_item_ctg_rec.fpg_category_set_id;
    l_ctg_hon_prod_rec.category_id     := i_item_ctg_rec.fpg_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_ctg_hon_prod_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_gic_fpg;
      RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END IF;
    --
    --==============================================================
    -- A-5.6-9 OPM�i�ڃJ�e�S������(�o�����p�Q�R�[�h)�o�^����
    --==============================================================
    lv_step := 'A-5.6-9';
    l_ctg_hon_prod_rec.item_id         := ln_item_id;
    l_ctg_hon_prod_rec.category_set_id := i_item_ctg_rec.apg_category_set_id;
    l_ctg_hon_prod_rec.category_id     := i_item_ctg_rec.apg_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_ctg_hon_prod_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_gic_apg;
      RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END IF;
-- 2009/09/07 Ver1.15 ��Q0001258 add end by Y.Kuboshima
    --==============================================================
    -- A-5.7 OPM�W�������o�^����
    -- �q�i�ڂ͕ύX�\��K�p�ōs���܂��B
    --==============================================================
    lv_step := 'A-5.7.1';
    -- �e�i�ڂ̏ꍇ�̂ݏ������܂��B
    IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
      -- ������
      ln_opm_cost_cnt := 0;
      ln_cmpnt_cost := NULL;
      --
      <<cmpnt_loop>>
      FOR opmcost_cmpnt_rec IN opmcost_cmpnt_cur( gd_process_date ) LOOP
        -- �����̎擾
        CASE opmcost_cmpnt_rec.cost_cmpntcls_code
--Ver1.12  2009/07/07  Mod  0000364�Ή�
--          WHEN cv_cost_cmpnt_01gen THEN    -- '01GEN'
--            -- ����
--            ln_cmpnt_cost := TO_NUMBER(i_wk_item_rec.standard_price_1);
--          WHEN cv_cost_cmpnt_02sai THEN    -- '02SAI'
--            -- �Đ���
--            ln_cmpnt_cost := TO_NUMBER(i_wk_item_rec.standard_price_2);
--          WHEN cv_cost_cmpnt_03szi THEN    -- '03SZI'
--            -- ���ޔ�
--            ln_cmpnt_cost := TO_NUMBER(i_wk_item_rec.standard_price_3);
--          WHEN cv_cost_cmpnt_04hou THEN    -- '04HOU'
--            -- ���
--            ln_cmpnt_cost := TO_NUMBER(i_wk_item_rec.standard_price_4);
--          WHEN cv_cost_cmpnt_05gai THEN    -- '05GAI'
--            -- �O���Ǘ���
--            ln_cmpnt_cost := TO_NUMBER(i_wk_item_rec.standard_price_5);
--          WHEN cv_cost_cmpnt_06hkn THEN    -- '06HKN'
--            -- �ۊǔ�
--            ln_cmpnt_cost := TO_NUMBER(i_wk_item_rec.standard_price_6);
--          WHEN cv_cost_cmpnt_07kei THEN    -- '07KEI'
--            -- ���̑��o��
--            ln_cmpnt_cost := TO_NUMBER(i_wk_item_rec.standard_price_7);
          --
          WHEN cv_cost_cmpnt_01gen THEN    -- '01GEN'
            -- ����
            ln_cmpnt_cost := TO_NUMBER( NVL( i_wk_item_rec.standard_price_1, 0) );
          WHEN cv_cost_cmpnt_02sai THEN    -- '02SAI'
            -- �Đ���
            ln_cmpnt_cost := TO_NUMBER( NVL( i_wk_item_rec.standard_price_2, 0) );
          WHEN cv_cost_cmpnt_03szi THEN    -- '03SZI'
            -- ���ޔ�
            ln_cmpnt_cost := TO_NUMBER( NVL( i_wk_item_rec.standard_price_3, 0) );
          WHEN cv_cost_cmpnt_04hou THEN    -- '04HOU'
            -- ���
            ln_cmpnt_cost := TO_NUMBER( NVL( i_wk_item_rec.standard_price_4, 0) );
          WHEN cv_cost_cmpnt_05gai THEN    -- '05GAI'
            -- �O���Ǘ���
            ln_cmpnt_cost := TO_NUMBER( NVL( i_wk_item_rec.standard_price_5, 0) );
          WHEN cv_cost_cmpnt_06hkn THEN    -- '06HKN'
            -- �ۊǔ�
            ln_cmpnt_cost := TO_NUMBER( NVL( i_wk_item_rec.standard_price_6, 0) );
          WHEN cv_cost_cmpnt_07kei THEN    -- '07KEI'
            -- ���̑��o��
            ln_cmpnt_cost := TO_NUMBER( NVL( i_wk_item_rec.standard_price_7, 0) );
          ELSE
            -- �\��1�`�\��3
            ln_cmpnt_cost := 0;
--End1.12
        END CASE;
        --
        -- �����ݒ蔻�f
        IF ( ln_cmpnt_cost IS NOT NULL ) THEN
          -- OPM�W�������w�b�_�p�����[�^�ݒ�
          IF ( ln_opm_cost_cnt = 0 ) THEN
            -- �J�����_�R�[�h
            l_opm_cost_header_rec.calendar_code := opmcost_cmpnt_rec.calendar_code;
            -- ���ԃR�[�h
            l_opm_cost_header_rec.period_code   := opmcost_cmpnt_rec.period_code;
            -- �i��ID
            l_opm_cost_header_rec.item_id       := ln_item_id;
          END IF;
          --
          -- �����o�^
          ln_opm_cost_cnt := ln_opm_cost_cnt + 1;
          -- ��������
          -- �����R���|�[�l���gID
          l_opm_cost_dist_tab(ln_opm_cost_cnt).cost_cmpntcls_id := opmcost_cmpnt_rec.cost_cmpntcls_id;
          -- ����
          l_opm_cost_dist_tab(ln_opm_cost_cnt).cmpnt_cost       := ln_cmpnt_cost;
          --
        END IF;
        --
      END LOOP cmpnt_loop;
      --
      lv_step := 'A-5.7.2';
      -- �W�������o�^
      xxcmm_004common_pkg.proc_opmcost_ref(
        i_cost_header_rec => l_opm_cost_header_rec                    -- 1.�����w�b�_���R�[�h�^�C�v
       ,i_cost_dist_tab   => l_opm_cost_dist_tab                      -- 2.�������׃e�[�u���^�C�v
       ,ov_errbuf         => lv_errbuf                                -- �G���[�E���b�Z�[�W
       ,ov_retcode        => lv_retcode                               -- ���^�[���E�R�[�h
       ,ov_errmsg         => lv_errmsg                                -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- �������ʃ`�F�b�N
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_tkn_table := cv_table_ccd;
        RAISE ins_err_expt;   -- �f�[�^�o�^��O
      END IF;
    END IF;
    --
    --==============================================================
    -- A-5.8 Disc�i�ڃA�h�I���o�^����
    --==============================================================
    lv_step := 'A-5.8';
    BEGIN
      INSERT INTO xxcmm_system_items_b(
        item_id
       ,item_code
       ,tax_rate
       ,baracha_div
       ,nets
       ,nets_uom_code
       ,inc_num
       ,vessel_group
       ,acnt_group
       ,acnt_vessel_group
       ,brand_group
       ,sp_supplier_code
       ,case_jan_code
       ,new_item_div
       ,bowl_inc_num
       ,item_status_apply_date
       ,item_status
       ,renewal_item_code
       ,search_update_date
-- Ver1.8  2009/05/18 Add  T1_0906 �P�[�X���Z������ǉ�
       ,case_conv_inc_num
-- End
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
        ln_item_id                                -- �i��ID
       ,i_wk_item_rec.item_code                   -- �i�ڃR�[�h
       ,NULL                                      -- ����ŗ�
       ,l_set_parent_item_rec.baracha_div         -- �o�����敪(�q�i�ڂ̏ꍇ�A�e�l�p������)
       ,l_set_parent_item_rec.nets                -- ���e��(�q�i�ڂ̏ꍇ�A�e�l�p������)
       ,l_set_parent_item_rec.nets_uom_code       -- ���e�ʒP��(�q�i�ڂ̏ꍇ�A�e�l�p������)
       ,l_set_parent_item_rec.inc_num             -- �������(�q�i�ڂ̏ꍇ�A�e�l�p������)
       ,l_set_parent_item_rec.vessel_group        -- �e��Q(�q�i�ڂ̏ꍇ�A�e�l�p������)
       ,l_set_parent_item_rec.acnt_group          -- �o���Q(�q�i�ڂ̏ꍇ�A�e�l�p������)
       ,l_set_parent_item_rec.acnt_vessel_group   -- �o���e��Q(�q�i�ڂ̏ꍇ�A�e�l�p������)
       ,l_set_parent_item_rec.brand_group         -- �u�����h�Q(�q�i�ڂ̏ꍇ�A�e�l�p������)
       ,l_set_parent_item_rec.sp_supplier_code    -- ���X�d����R�[�h(�q�i�ڂ̏ꍇ�A�e�l�p�����ځ����i���i�敪���u1:���i�v�̏ꍇ)
       ,l_set_parent_item_rec.case_jan_code       -- �P�[�XJAN�R�[�h(�q�i�ڂ̏ꍇ�A�e�l�p������)
       ,i_wk_item_rec.new_item_div                -- �V���i�敪
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 modify start by Shigeto.Niki
--       ,l_set_parent_item_rec.bowl_inc_num        -- �{�[������(�q�i�ڂ̏ꍇ�A�e�l�p������)
       ,i_wk_item_rec.bowl_inc_num                -- �{�[������
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 modify end by Shigeto.Niki
       ,NULL                                      -- �i�ڃX�e�[�^�X�K�p��
       ,NULL                                      -- �i�ڃX�e�[�^�X
       ,i_wk_item_rec.renewal_item_code           -- ���j���[�A�������i�R�[�h
-- Ver.1.5 20090224 Mod START
       ,gd_process_date                           -- �����ΏۍX�V��
--       ,cd_creation_date                          -- �����ΏۍX�V��
-- Ver.1.5 20090224 Mod END
-- Ver1.8  2009/05/18 Add  T1_0906 �P�[�X���Z������ǉ�
       ,l_set_parent_item_rec.case_conv_inc_num   -- �P�[�X���Z����
-- End
       ,cn_created_by                             -- �쐬��
       ,cd_creation_date                          -- �쐬��
       ,cn_last_updated_by                        -- �ŏI�X�V��
       ,cd_last_update_date                       -- �ŏI�X�V��
       ,cn_last_update_login                      -- �ŏI�X�V���O�C��
       ,cn_request_id                             -- �v��ID
       ,cn_program_application_id                 -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
       ,cn_program_id                             -- �R���J�����g�E�v���O����ID
       ,cd_program_update_date                    -- �v���O�����ɂ��X�V��
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf    := SQLERRM;
        lv_tkn_table := cv_table_xsib;
        RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END;
    --
    --==============================================================
    -- A-5.9 Disc�i�ڕύX�����A�h�I���o�^����
    --==============================================================
    lv_step := 'A-5.9';
-- Ver.1.5 20090224 Add START
    -- �e�i�ڂ̏ꍇ�Acsv�l���Z�b�g���܂��B
    IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
      ln_fixed_price   := TO_NUMBER(i_wk_item_rec.list_price);
      ln_discrete_cost := TO_NUMBER(i_wk_item_rec.business_price);
      lv_policy_group  := i_wk_item_rec.policy_group;
    ELSE
    -- �q�i�ڂ̏ꍇ�A�e�l�p������(�艿,�c�ƌ���,����Q)��NULL���Z�b�g���܂��B
      ln_fixed_price   := NULL;
      ln_discrete_cost := NULL;
      lv_policy_group  := NULL;
    END IF;
-- Ver.1.5 20090224 Add END
    BEGIN
      INSERT INTO xxcmm_system_items_b_hst(
        item_hst_id
       ,item_id
       ,item_code
       ,apply_date
       ,apply_flag
       ,item_status
       ,policy_group
       ,fixed_price
       ,discrete_cost
       ,first_apply_flag
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
        xxcmm_system_items_b_hst_s.NEXTVAL        -- �i�ڕύX����ID
       ,ln_item_id                                -- �i��ID
       ,i_wk_item_rec.item_code                   -- �i�ڃR�[�h
       ,gd_process_date                           -- �K�p���i�K�p�J�n���j
       ,cv_no                                     -- �K�p�L��(N�Œ�)
       ,cn_itm_status_regist                      -- �i�ڃX�e�[�^�X(�{�o�^�Œ�)
-- Ver.1.5 20090224 Mod START
       ,lv_policy_group                           -- �Q�R�[�h�i����Q�R�[�h�j
       ,ln_fixed_price                            -- �艿
       ,ln_discrete_cost                          -- �c�ƌ���
--       ,i_wk_item_rec.policy_group                -- �Q�R�[�h�i����Q�R�[�h�j
--       ,i_wk_item_rec.list_price                  -- �艿
--       ,i_wk_item_rec.business_price              -- �c�ƌ���
-- Ver.1.5 20090224 Mod START
       ,cv_yes                                    -- ����K�p�t���O(Y�Œ�)
       ,cn_created_by                             -- �쐬��
       ,cd_creation_date                          -- �쐬��
       ,cn_last_updated_by                        -- �ŏI�X�V��
       ,cd_last_update_date                       -- �ŏI�X�V��
       ,cn_last_update_login                      -- �ŏI�X�V���O�C��
       ,cn_request_id                             -- �v��ID
       ,cn_program_application_id                 -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
       ,cn_program_id                             -- �R���J�����g�E�v���O����ID
       ,cd_program_update_date                    -- �v���O�����ɂ��X�V��
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf    := SQLERRM;
        lv_tkn_table := cv_table_xsibh;
        RAISE ins_err_expt;   -- �f�[�^�o�^��O
    END;
  --
  EXCEPTION
    -- *** �f�[�^�o�^��O�n���h�� ***
    WHEN ins_err_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00407            -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_table                  -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_input_line_no          -- �g�[�N���R�[�h2
                    ,iv_token_value2 => i_wk_item_rec.line_no         -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_input_item_code        -- �g�[�N���R�[�h3
                    ,iv_token_value3 => i_wk_item_rec.item_code       -- �g�[�N���l3
                    ,iv_token_name4  => cv_tkn_errmsg                 -- �g�[�N���R�[�h4
                    ,iv_token_value4 => lv_errbuf                     -- �g�[�N���l4
                   );
      -- ���b�Z�[�W�o��
      xxcmm_004common_pkg.put_message(
        iv_message_buff  =>  lv_errmsg
       ,ov_errbuf        =>  lv_errbuf
       ,ov_retcode       =>  lv_retcode
       ,ov_errmsg        =>  lv_errmsg
      );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_data;
--
  /**********************************************************************************
   * Procedure Name   : validate_item
   * Description      : �i�ڈꊇ�o�^���[�N�f�[�^�Ó����`�F�b�N (A-4)
   ***********************************************************************************/
  PROCEDURE validate_item(
    i_wk_item_rec  IN  xxcmm_wk_item_batch_regist%ROWTYPE                  -- �i�ڈꊇ�o�^���[�N���
   ,o_item_ctg_rec OUT g_item_ctg_rtype                                    -- �J�e�S�����
   ,o_etc_rec      OUT g_etc_rtype                                         -- ���̑����
   ,ov_errbuf      OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_item';              -- �v���O������
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
    -- *** ���[�J���萔 ***
-- Ver1.7  2009/04/10  Add  ��QT1_0219 �Ή�
    cv_uom_code_kg            CONSTANT VARCHAR2(3) := 'kg';
    cv_uom_code_l             CONSTANT VARCHAR2(3) := 'L';
-- End
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(10);                           -- �X�e�b�v
    lv_tkn_value              VARCHAR2(100);                          -- �g�[�N���l
    ln_cnt                    NUMBER;                                 -- �J�E���g�p
    ln_cnt_all                NUMBER;                                 -- �J�E���g�p(�S��)
    ln_parent_item_status     xxcmm_system_items_b.item_status%TYPE;  -- �e�i�ڃX�e�[�^�X
    lv_check_flag             VARCHAR2(1);                            -- �`�F�b�N�t���O
    l_validate_item_tab       g_check_data_ttype;
    --
    l_item_ctg_rec            g_item_ctg_rtype;                       -- �J�e�S�����
    l_lookup_rec              g_lookup_rtype;                         -- LOOKUP���
    --
    ln_opm_cost_total         cm_cmpt_dtl.cmpnt_cost%TYPE;            -- �W���������v�l
    --
    lv_category_val           VARCHAR2(240);                          -- �J�e�S���l
-- Ver1.8  2009/05/18 Add  T1_0322 �q�i�ڂŏ��i���i�敪���o���ɐe�i�ڂ̏��i���i�敪�Ɣ�r������ǉ�
    lv_p_item_prod_class      VARCHAR2(240);                          -- �e�i�� ���i���i�敪
-- End
-- Ver1.11  2009/06/11  Add Start
    ln_baracha_category_id     mtl_categories_b.category_id%TYPE;         -- �J�e�S��ID�i�o�����敪�j
    ln_baracha_category_set_id mtl_category_sets_b.category_set_id%TYPE;  -- �J�e�S���Z�b�gID�i�o�����敪�j
    ln_markpg_category_id      mtl_categories_b.category_id%TYPE;         -- �J�e�S��ID�i�}�[�P�p�Q�R�[�h�j
    ln_markpg_category_set_id  mtl_category_sets_b.category_set_id%TYPE;  -- �J�e�S���Z�b�gID�i�}�[�P�p�Q�R�[�h�j
    ln_pg_category_id          mtl_categories_b.category_id%TYPE;         -- �J�e�S��ID�i�Q�R�[�h�j
    ln_pg_category_set_id      mtl_category_sets_b.category_set_id%TYPE;  -- �J�e�S���Z�b�gID�i�Q�R�[�h�j
-- Ver1.11  2009/06/11  End
    --
    ln_check_cnt              NUMBER;
    lv_required_item          VARCHAR2(2000);
    lv_sqlerrm                VARCHAR2(5000);                         -- SQLERRM�ϐ��ޔ�p
-- 2009/08/07 Ver1.14 ��Q0000948 add start by Y.Kuboshima
    ln_chk_stand_unit         NUMBER;                                 -- ��P�ʑ��݃`�F�b�N�p�ϐ�
-- 2009/08/07 Ver1.14 ��Q0000948 add end by Y.Kuboshima
--
    -- *** ���[�J���E�J�[�\�� ***
-- Ver1.11  2009/06/11  Add Start
    -- �J�e�S���Z�b�gID�E�J�e�S��ID�擾�J�[�\��
    CURSOR get_categ_cur(
      pv_item_code    VARCHAR2
     ,pv_categ_name   VARCHAR2 )
    IS
      SELECT    mcv.category_id
               ,mcsv.category_set_id
      FROM      ic_item_mst_b         iimb
               ,gmi_item_categories  gic
               ,mtl_category_sets_vl mcsv
               ,mtl_categories_vl    mcv
      WHERE     iimb.item_no           = pv_item_code
      AND       mcsv.category_set_name = pv_categ_name
      AND       gic.item_id            = iimb.item_id
      AND       gic.category_set_id    = mcsv.category_set_id
      AND       gic.category_id        = mcv.category_id;
-- Ver1.11  2009/06/11  End
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �`�F�b�N�t���O�̏�����
    lv_check_flag := cv_status_normal;
    --
    -- �J�e�S����񏉊���
    l_item_ctg_rec := NULL;
    --
    --==============================================================
    -- ���C������LOOP
    --==============================================================
    lv_step := 'A-4.1';
    --
    l_validate_item_tab(1)  := i_wk_item_rec.line_no;                 -- �s�ԍ�
    l_validate_item_tab(2)  := i_wk_item_rec.item_code;               -- �i���R�[�h
    l_validate_item_tab(3)  := i_wk_item_rec.item_name;               -- ������
    l_validate_item_tab(4)  := i_wk_item_rec.item_short_name;         -- ����
    l_validate_item_tab(5)  := i_wk_item_rec.item_name_alt;           -- �J�i��
    l_validate_item_tab(6)  := i_wk_item_rec.item_status;             -- �i�ڃX�e�[�^�X
    l_validate_item_tab(7)  := i_wk_item_rec.sales_target_flag;       -- ����Ώۋ敪
    l_validate_item_tab(8)  := i_wk_item_rec.parent_item_code;        -- �e���i�R�[�h
    l_validate_item_tab(9)  := i_wk_item_rec.case_inc_num;            -- �P�[�X����
-- Ver1.8  2009/05/18 Add  T1_0906 �P�[�X���Z������ǉ�
    l_validate_item_tab(10) := i_wk_item_rec.case_conv_inc_num;       -- �P�[�X���Z����
-- End
    l_validate_item_tab(11) := i_wk_item_rec.item_um;                 -- ��P��
    l_validate_item_tab(12) := i_wk_item_rec.item_product_class;      -- ���i���i�敪
    l_validate_item_tab(13) := i_wk_item_rec.rate_class;              -- ���敪
    l_validate_item_tab(14) := i_wk_item_rec.net;                     -- NET
    l_validate_item_tab(15) := i_wk_item_rec.weight_volume;           -- �d�ʁ^�̐�
    l_validate_item_tab(16) := i_wk_item_rec.jan_code;                -- JAN�R�[�h
    l_validate_item_tab(17) := i_wk_item_rec.nets;                    -- ���e��
    l_validate_item_tab(18) := i_wk_item_rec.nets_uom_code;           -- ���e�ʒP��
    l_validate_item_tab(19) := i_wk_item_rec.inc_num;                 -- �������
    l_validate_item_tab(20) := i_wk_item_rec.case_jan_code;           -- �P�[�XJAN�R�[�h
    l_validate_item_tab(21) := i_wk_item_rec.hon_product_class;       -- �{�Џ��i�敪
    l_validate_item_tab(22) := i_wk_item_rec.baracha_div;             -- �o�����敪
    l_validate_item_tab(23) := i_wk_item_rec.itf_code;                -- ITF�R�[�h
    l_validate_item_tab(24) := i_wk_item_rec.product_class;           -- ���i����
    l_validate_item_tab(25) := i_wk_item_rec.palette_max_cs_qty;      -- �z��
    l_validate_item_tab(26) := i_wk_item_rec.palette_max_step_qty;    -- �i��
    l_validate_item_tab(27) := i_wk_item_rec.bowl_inc_num;            -- �{�[������
    l_validate_item_tab(28) := i_wk_item_rec.sale_start_date;         -- �����J�n��
    l_validate_item_tab(29) := i_wk_item_rec.vessel_group;            -- �e��Q
    l_validate_item_tab(30) := i_wk_item_rec.new_item_div;            -- �V���i�敪
    l_validate_item_tab(31) := i_wk_item_rec.acnt_group;              -- �o���Q
    l_validate_item_tab(32) := i_wk_item_rec.acnt_vessel_group;       -- �o���e��Q
    l_validate_item_tab(33) := i_wk_item_rec.brand_group;             -- �u�����h�Q
    l_validate_item_tab(34) := i_wk_item_rec.policy_group;            -- ����Q
    l_validate_item_tab(35) := i_wk_item_rec.list_price;              -- �艿
    l_validate_item_tab(36) := i_wk_item_rec.standard_price_1;        -- ����(�W������)
    l_validate_item_tab(37) := i_wk_item_rec.standard_price_2;        -- �Đ���(�W������)
    l_validate_item_tab(38) := i_wk_item_rec.standard_price_3;        -- ���ޔ�(�W������)
    l_validate_item_tab(39) := i_wk_item_rec.standard_price_4;        -- ���(�W������)
    l_validate_item_tab(40) := i_wk_item_rec.standard_price_5;        -- �O���Ǘ���(�W������)
    l_validate_item_tab(41) := i_wk_item_rec.standard_price_6;        -- �ۊǔ�(�W������)
    l_validate_item_tab(42) := i_wk_item_rec.standard_price_7;        -- ���̑��o��(�W������)
    l_validate_item_tab(43) := i_wk_item_rec.business_price;          -- �c�ƌ���
    l_validate_item_tab(44) := i_wk_item_rec.renewal_item_code;       -- ���j���[�A�������i�R�[�h
    l_validate_item_tab(45) := i_wk_item_rec.sp_supplier_code;        -- ���X�d����R�[�h
    --
    -- �J�E���^�̏�����
    ln_check_cnt := 0;
    --
    <<validate_column_loop>>
    LOOP
      EXIT WHEN ln_check_cnt >= gn_item_num;
      -- �J�E���^�����Z
      ln_check_cnt := ln_check_cnt + 1;
-- Ver1.8  2009/05/19  �o�O�H�H  �㏑�����ꂽ���i���i�敪������悤�C��
      -- �N���A
      lv_p_item_prod_class := NULL;
-- End
      --
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => g_item_def_tab(ln_check_cnt).item_name                         -- ���ږ���
       ,iv_item_value   => l_validate_item_tab(ln_check_cnt)                              -- ���ڂ̒l
       ,in_item_len     => g_item_def_tab(ln_check_cnt).item_length                       -- ���ڂ̒���(��������)
       ,in_item_decimal => g_item_def_tab(ln_check_cnt).decim                             -- ���ڂ̒����i�����_�ȉ��j
       ,iv_item_nullflg => g_item_def_tab(ln_check_cnt).item_essential                    -- �K�{�t���O
       ,iv_item_attr    => g_item_def_tab(ln_check_cnt).item_attribute                    -- ���ڂ̑���
       ,ov_errbuf       => lv_errbuf
       ,ov_retcode      => lv_retcode
       ,ov_errmsg       => lv_errmsg
      );
      -- �������ʃ`�F�b�N
      IF ( lv_retcode <> cv_status_normal ) THEN                                          -- �߂�l���ȏ�̏ꍇ
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm                          -- �A�v���P�[�V�����Z�k��
                        ,iv_name          =>  cv_msg_xxcmm_00403                          -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   =>  cv_tkn_input_line_no                        -- �g�[�N���R�[�h1
                        ,iv_token_value1  =>  i_wk_item_rec.line_no                       -- �g�[�N���l1
                        ,iv_token_name2   =>  cv_tkn_errmsg                               -- �g�[�N���R�[�h2
                        ,iv_token_value2  =>  LTRIM(lv_errmsg)                            -- �g�[�N���l2
                       );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff  =>  lv_errmsg
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
        lv_check_flag := cv_status_error;
      END IF;
    END LOOP validate_column_loop;
    --
    IF ( lv_check_flag = cv_status_normal ) THEN
      --==============================================================
      -- A-4.2 �i�ڑ��݃`�F�b�N
      --==============================================================
      lv_step := 'A-4.2';
      SELECT  COUNT(1)
      INTO    ln_cnt
      FROM    ic_item_mst_b iimb
      WHERE   iimb.item_no = i_wk_item_rec.item_code
      AND     ROWNUM       = 1
      ;
      -- �������ʃ`�F�b�N
      IF ( ln_cnt > 0 ) THEN
        -- �}�X�^���݃`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00404          -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input_line_no        -- �g�[�N���R�[�h1
                      ,iv_token_value1 => i_wk_item_rec.line_no       -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_input_item_code      -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_item_rec.item_code     -- �g�[�N���l2
                     );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.3 �i�ڏd���`�F�b�N
      --==============================================================
      lv_step := 'A-4.3';
      SELECT  COUNT(1)
             ,COUNT(DISTINCT xwibr.item_code)
      INTO    ln_cnt_all
             ,ln_cnt
      FROM    xxcmm_wk_item_batch_regist xwibr
      WHERE   xwibr.item_code = i_wk_item_rec.item_code
      AND     xwibr.request_id = cn_request_id
      ;
      -- �������ʃ`�F�b�N
      IF ( ln_cnt_all <> ln_cnt ) THEN
        -- �i�ڏd���G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00405          -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input_line_no        -- �g�[�N���R�[�h1
                      ,iv_token_value1 => i_wk_item_rec.line_no       -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_input_item_code      -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_item_rec.item_code     -- �g�[�N���l2
                     );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.4 �q�i�ڎ��A�e�i�ڃX�e�[�^�X�`�F�b�N
      --==============================================================
      lv_step := 'A-4.4';
      -- �q�i�ڎ�
      IF ( i_wk_item_rec.item_code <> i_wk_item_rec.parent_item_code ) THEN
        -- �e�i�ڃX�e�[�^�X���o
        SELECT  xsib.item_status
        INTO    ln_parent_item_status
        FROM    ic_item_mst_b        iimb
               ,xxcmm_system_items_b xsib
        WHERE   iimb.item_no = xsib.item_code
        AND     iimb.item_no = i_wk_item_rec.parent_item_code
        ;
        -- �������ʃ`�F�b�N
        IF ( NVL( ln_parent_item_status, cn_itm_status_num_tmp ) <> cn_itm_status_regist ) THEN
          -- �e�i�ڃX�e�[�^�X�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm        -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_00406        -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input_line_no      -- �g�[�N���R�[�h1
                        ,iv_token_value1 => i_wk_item_rec.line_no     -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_input_item_code    -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_item_rec.item_code   -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_item_status        -- �g�[�N���R�[�h3
                        ,iv_token_value3 => ln_parent_item_status     -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --
      --==============================================================
      -- A-4.5 �e�i�ڕK�{�`�F�b�N
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 modify start by Shigeto.Niki
--      -- ����Ώ�,�P�[�X����,��P��,���i���i�敪,���敪,NET,�d�ʁ^�̐�,
      -- ����Ώ�,�P�[�X����,��P��,���i���i�敪,���敪,      
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 modify end by Shigeto.Niki
      -- ���e��,���e�ʒP��,�������,�{�Џ��i�敪,�o�����敪,
      -- ����Q,�艿,�W������,�c�ƌ���
      --==============================================================
      lv_step := 'A-4.5';
      --
      -- ������
      lv_required_item := NULL;
      --
      -- �e�i�ڎ�
      IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
        -- ����Ώۋ敪
        IF ( i_wk_item_rec.sales_target_flag IS NULL ) THEN
          lv_required_item := cv_sales_target_flag;
        END IF;
        --
        -- �P�[�X����
        IF ( i_wk_item_rec.case_inc_num IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_case_inc_num;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_case_inc_num;
          END IF;
-- 2009/10/14 ��Q0001370 add start by Y.Kuboshima
        -- �P�[�X������0�ȉ��̏ꍇ
        ELSIF ( i_wk_item_rec.case_inc_num < 1 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm           -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_00493           -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                 -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_case_inc_num              -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                 -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_item_rec.case_inc_num   -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no         -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_item_rec.line_no        -- �g�[�N���l3
                        ,iv_token_name4  => cv_tkn_input_item_code       -- �g�[�N���R�[�h4
                        ,iv_token_value4 => i_wk_item_rec.item_code      -- �g�[�N���l4
                       );
          -- ���b�Z�[�W�o��
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          lv_check_flag := cv_status_error;
-- 2009/10/14 ��Q0001370 add end by Y.Kuboshima
        END IF;
        --
-- 2009/10/14 ��Q0001370 add start by Y.Kuboshima
        -- �P�[�X���Z����
        -- �P�[�X���Z������NOT NULL���A0�ȉ��̏ꍇ
        -- ���P�[�X���Z������NULL�̏ꍇ�͎����v�Z����邽�߁A�G���[�`�F�b�N��NOT NULL�̏ꍇ�̂�
        IF    ( i_wk_item_rec.case_conv_inc_num  IS NOT NULL)
          AND ( i_wk_item_rec.case_conv_inc_num < 1 )
        THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm              -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_00493              -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                    -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_case_conv_inc_num            -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                    -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_item_rec.case_conv_inc_num -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no            -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_item_rec.line_no           -- �g�[�N���l3
                        ,iv_token_name4  => cv_tkn_input_item_code          -- �g�[�N���R�[�h4
                        ,iv_token_value4 => i_wk_item_rec.item_code         -- �g�[�N���l4
                       );
          -- ���b�Z�[�W�o��
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          lv_check_flag := cv_status_error;
        END IF;
-- 2009/10/14 ��Q0001370 add end by Y.Kuboshima
        --
        -- ��P��
        IF ( i_wk_item_rec.item_um IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_item_um;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_item_um;
          END IF;
        END IF;
        --
        -- ���i���i�敪
        IF ( i_wk_item_rec.item_product_class IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_item_product_class;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_item_product_class;
          END IF;
        END IF;
        --
        -- ���敪
        IF ( i_wk_item_rec.rate_class IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_rate_class;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_rate_class;
          END IF;
        END IF;
        --
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete start by Shigeto.Niki
--        -- �d�ʁ^�̐�
--        IF ( i_wk_item_rec.weight_volume IS NULL ) THEN
--          IF ( lv_required_item IS NULL ) THEN
--            lv_required_item := cv_weight_volume;
--          ELSE
--            lv_required_item := lv_required_item || cv_msg_comma_double || cv_weight_volume;
--          END IF;
---- 2009/10/14 ��Q0001370 add start by Y.Kuboshima
--        -- �d�ʁ^�̐ς�0�ȉ��̏ꍇ
--        ELSIF ( i_wk_item_rec.weight_volume < 1 ) THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_appl_name_xxcmm           -- �A�v���P�[�V�����Z�k��
--                        ,iv_name         => cv_msg_xxcmm_00493           -- ���b�Z�[�W�R�[�h
--                        ,iv_token_name1  => cv_tkn_input                 -- �g�[�N���R�[�h1
--                        ,iv_token_value1 => cv_weight_volume             -- �g�[�N���l1
--                        ,iv_token_name2  => cv_tkn_value                 -- �g�[�N���R�[�h2
--                        ,iv_token_value2 => i_wk_item_rec.weight_volume  -- �g�[�N���l2
--                        ,iv_token_name3  => cv_tkn_input_line_no         -- �g�[�N���R�[�h3
--                        ,iv_token_value3 => i_wk_item_rec.line_no        -- �g�[�N���l3
--                        ,iv_token_name4  => cv_tkn_input_item_code       -- �g�[�N���R�[�h4
--                        ,iv_token_value4 => i_wk_item_rec.item_code      -- �g�[�N���l4
--                       );
--          -- ���b�Z�[�W�o��
--          xxcmm_004common_pkg.put_message(
--            iv_message_buff => lv_errmsg
--           ,ov_errbuf       => lv_errbuf
--           ,ov_retcode      => lv_retcode
--           ,ov_errmsg       => lv_errmsg
--          );
--          lv_check_flag := cv_status_error;
---- 2009/10/14 ��Q0001370 add end by Y.Kuboshima
--        END IF;
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete end by Shigeto.Niki
        --
        -- ���e��
        IF ( i_wk_item_rec.nets IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_nets;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_nets;
          END IF;
-- 2009/10/14 ��Q0001370 add start by Y.Kuboshima
        -- ���e�ʂ�0�ȉ��̏ꍇ
        ELSIF ( i_wk_item_rec.nets < 1 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm           -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_00493           -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                 -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_nets                      -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                 -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_item_rec.nets           -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no         -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_item_rec.line_no        -- �g�[�N���l3
                        ,iv_token_name4  => cv_tkn_input_item_code       -- �g�[�N���R�[�h4
                        ,iv_token_value4 => i_wk_item_rec.item_code      -- �g�[�N���l4
                       );
          -- ���b�Z�[�W�o��
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          lv_check_flag := cv_status_error;
-- 2009/10/14 ��Q0001370 add end by Y.Kuboshima
        END IF;
        --
        -- ���e�ʒP��
        IF ( i_wk_item_rec.nets_uom_code IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_nets_uom_code;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_nets_uom_code;
          END IF;
        END IF;
        --
        -- �������
        IF ( i_wk_item_rec.inc_num IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_inc_num;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_inc_num;
          END IF;
-- 2009/10/14 ��Q0001370 add start by Y.Kuboshima
        -- ���������0�ȉ��̏ꍇ
        ELSIF ( i_wk_item_rec.inc_num < 1 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm           -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_00493           -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                 -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_inc_num                   -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                 -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_item_rec.inc_num        -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no         -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_item_rec.line_no        -- �g�[�N���l3
                        ,iv_token_name4  => cv_tkn_input_item_code       -- �g�[�N���R�[�h4
                        ,iv_token_value4 => i_wk_item_rec.item_code      -- �g�[�N���l4
                       );
          -- ���b�Z�[�W�o��
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          lv_check_flag := cv_status_error;
-- 2009/10/14 ��Q0001370 add end by Y.Kuboshima
        END IF;
        --
-- Ver1.7  2009/04/10  Add  ��QT1_0219 �Ή�
        -- NET�i�ő�8���j
        IF  ( i_wk_item_rec.nets_uom_code IN ( cv_uom_code_kg, cv_uom_code_l ))
        AND ( i_wk_item_rec.net IS NULL ) THEN
          -- ���e�ʒP�ʂ�'KG'�A'L'�̏ꍇ�A*1000����K�v�����邽�߁A
          -- NET(6��)���I�[�o�[���Ȃ����`�F�b�N�i5�����I�[�o�[���Ȃ���΍ő�8���Ɏ��܂�j
          IF ( TRUNC( NVL( i_wk_item_rec.nets, 0 ) * NVL( i_wk_item_rec.inc_num, 0 ) ) >= 100000 ) THEN
            -- ���e�ʁA������� �Ƃ��ɐݒ肳��Ă���ꍇ�ANET�����G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm           -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_xxcmm_00428           -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_input_line_no         -- �g�[�N���R�[�h1
                          ,iv_token_value1 => i_wk_item_rec.line_no        -- �g�[�N���l1
                          ,iv_token_name2  => cv_tkn_input_item_code       -- �g�[�N���R�[�h2
                          ,iv_token_value2 => i_wk_item_rec.item_code      -- �g�[�N���l2
                          ,iv_token_name3  => cv_tkn_nets_uom_code         -- �g�[�N���R�[�h3
                          ,iv_token_value3 => i_wk_item_rec.nets_uom_code  -- �g�[�N���l3
                          ,iv_token_name4  => cv_tkn_nets                  -- �g�[�N���R�[�h4
                          ,iv_token_value4 => i_wk_item_rec.nets           -- �g�[�N���l4
                          ,iv_token_name5  => cv_tkn_inc_num               -- �g�[�N���R�[�h5
                          ,iv_token_value5 => i_wk_item_rec.inc_num        -- �g�[�N���l5
                         );
            -- ���b�Z�[�W�o��
            xxcmm_004common_pkg.put_message(
              iv_message_buff => lv_errmsg
             ,ov_errbuf       => lv_errbuf
             ,ov_retcode      => lv_retcode
             ,ov_errmsg       => lv_errmsg
            );
            lv_check_flag := cv_status_error;
          END IF;
-- 2009/10/14 ��Q0001370 add start by Y.Kuboshima
        -- NET��NOT NULL���A0�ȉ��̏ꍇ
        -- ��NET��NULL�̏ꍇ�͎����v�Z����邽�߁A�G���[�`�F�b�N��NOT NULL�̏ꍇ�̂�
        ELSIF ( i_wk_item_rec.net IS NOT NULL )
          AND ( i_wk_item_rec.net < 1 )
        THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm           -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_00493           -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                 -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_net                       -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                 -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_item_rec.net            -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no         -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_item_rec.line_no        -- �g�[�N���l3
                        ,iv_token_name4  => cv_tkn_input_item_code       -- �g�[�N���R�[�h4
                        ,iv_token_value4 => i_wk_item_rec.item_code      -- �g�[�N���l4
                       );
          -- ���b�Z�[�W�o��
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          lv_check_flag := cv_status_error;
-- 2009/10/14 ��Q0001370 add end by Y.Kuboshima
        END IF;
-- End
-- 2010/01/06 Ver1.18 ��QE_�{�ғ�_00614 delete start by Shigeto.Niki
---- 2009/10/14 ��Q0001370 add start by Y.Kuboshima
--        -- �z��
--        -- �z����NOT NULL���A0�ȉ��̏ꍇ
--        -- ���z����NULL�`�F�b�N�͌㑱�ōs�����߁A�����ł�NULL�`�F�b�N�͍s��Ȃ�
--        IF    ( i_wk_item_rec.palette_max_cs_qty  IS NOT NULL)
--          AND ( i_wk_item_rec.palette_max_cs_qty < 1 )
---- 2009/12/07 Ver1.17 E_�{�ғ�_00358 add start by Y.Kuboshima
--          -- �{�Џ��i�敪���u2�F�h�����N�v�̏ꍇ�̏����ǉ�
--          AND ( i_wk_item_rec.hon_product_class = cn_hon_prod_drink)
---- 2009/12/07 Ver1.17 E_�{�ғ�_00358 add end by Y.Kuboshima
--        THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_appl_name_xxcmm               -- �A�v���P�[�V�����Z�k��
--                        ,iv_name         => cv_msg_xxcmm_00493               -- ���b�Z�[�W�R�[�h
--                        ,iv_token_name1  => cv_tkn_input                     -- �g�[�N���R�[�h1
--                        ,iv_token_value1 => cv_pale_max_cs_qty               -- �g�[�N���l1
--                        ,iv_token_name2  => cv_tkn_value                     -- �g�[�N���R�[�h2
--                        ,iv_token_value2 => i_wk_item_rec.palette_max_cs_qty -- �g�[�N���l2
--                        ,iv_token_name3  => cv_tkn_input_line_no             -- �g�[�N���R�[�h3
--                        ,iv_token_value3 => i_wk_item_rec.line_no            -- �g�[�N���l3
--                        ,iv_token_name4  => cv_tkn_input_item_code           -- �g�[�N���R�[�h4
--                        ,iv_token_value4 => i_wk_item_rec.item_code          -- �g�[�N���l4
--                       );
--          -- ���b�Z�[�W�o��
--          xxcmm_004common_pkg.put_message(
--            iv_message_buff => lv_errmsg
--           ,ov_errbuf       => lv_errbuf
--           ,ov_retcode      => lv_retcode
--           ,ov_errmsg       => lv_errmsg
--          );
--          lv_check_flag := cv_status_error;
--        END IF;
--        --
--        -- �i��
--        -- �i����NOT NULL���A0�ȉ��̏ꍇ
--        -- ���i����NULL�`�F�b�N�͌㑱�ōs�����߁A�����ł�NULL�`�F�b�N�͍s��Ȃ�
--        IF    ( i_wk_item_rec.palette_max_step_qty  IS NOT NULL)
--          AND ( i_wk_item_rec.palette_max_step_qty < 1 )
---- 2009/12/07 Ver1.17 E_�{�ғ�_00358 add start by Y.Kuboshima
--          -- �{�Џ��i�敪���u2�F�h�����N�v�̏ꍇ�̏����ǉ�
--          AND ( i_wk_item_rec.hon_product_class = cn_hon_prod_drink)
---- 2009/12/07 Ver1.17 E_�{�ғ�_00358 add end by Y.Kuboshima
--        THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_appl_name_xxcmm                 -- �A�v���P�[�V�����Z�k��
--                        ,iv_name         => cv_msg_xxcmm_00493                 -- ���b�Z�[�W�R�[�h
--                        ,iv_token_name1  => cv_tkn_input                       -- �g�[�N���R�[�h1
--                        ,iv_token_value1 => cv_pale_max_step_qty               -- �g�[�N���l1
--                        ,iv_token_name2  => cv_tkn_value                       -- �g�[�N���R�[�h2
--                        ,iv_token_value2 => i_wk_item_rec.palette_max_step_qty -- �g�[�N���l2
--                        ,iv_token_name3  => cv_tkn_input_line_no               -- �g�[�N���R�[�h3
--                        ,iv_token_value3 => i_wk_item_rec.line_no              -- �g�[�N���l3
--                        ,iv_token_name4  => cv_tkn_input_item_code             -- �g�[�N���R�[�h4
--                        ,iv_token_value4 => i_wk_item_rec.item_code            -- �g�[�N���l4
--                       );
--          -- ���b�Z�[�W�o��
--          xxcmm_004common_pkg.put_message(
--            iv_message_buff => lv_errmsg
--           ,ov_errbuf       => lv_errbuf
--           ,ov_retcode      => lv_retcode
--           ,ov_errmsg       => lv_errmsg
--          );
--          lv_check_flag := cv_status_error;
--        END IF;
---- 2009/10/14 ��Q0001370 add end by Y.Kuboshima
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete end by Shigeto.Niki
        --
        -- �{�Џ��i�敪
        IF ( i_wk_item_rec.hon_product_class IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_hon_product_class;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_hon_product_class;
          END IF;
        END IF;
        --
        -- �o�����敪
        IF ( i_wk_item_rec.baracha_div IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_baracha_div;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_baracha_div;
          END IF;
        END IF;
        --
        -- ����Q
        IF ( i_wk_item_rec.policy_group IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_policy_group;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_policy_group;
          END IF;
        END IF;
        --
        -- �艿
        IF ( i_wk_item_rec.list_price IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_list_price;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_list_price;
          END IF;
        END IF;
        --
        -- �W������(����,�Đ���,���ޔ�,���,�O���Ǘ���,�ۊǔ�,���̑��o��)�S��NULL�̏ꍇ
        IF (  ( i_wk_item_rec.standard_price_1 IS NULL )
          AND ( i_wk_item_rec.standard_price_2 IS NULL )
          AND ( i_wk_item_rec.standard_price_3 IS NULL )
          AND ( i_wk_item_rec.standard_price_4 IS NULL )
          AND ( i_wk_item_rec.standard_price_5 IS NULL )
          AND ( i_wk_item_rec.standard_price_6 IS NULL )
          AND ( i_wk_item_rec.standard_price_7 IS NULL )) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_standard_price;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_standard_price;
          END IF;
        END IF;
        --
        -- �c�ƌ���
        IF ( i_wk_item_rec.business_price IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_business_price;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_business_price;
          END IF;
        END IF;
        --
        IF ( lv_required_item IS NOT NULL ) THEN
          -- �e�i�ڕK�{�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_00419          -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input_line_no        -- �g�[�N���R�[�h1
                        ,iv_token_value1 => i_wk_item_rec.line_no       -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_input_col_name       -- �g�[�N���R�[�h2
                        ,iv_token_value2 => lv_required_item            -- �g�[�N���l2
                       );
          -- ���b�Z�[�W�o��
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --
      --==============================================================
      -- A-4.6 �i���R�[�h�`�F�b�N
      --==============================================================
      lv_step := 'A-4.6.1';
      -- �i���R�[�h7���K�{�`�F�b�N
      IF ( LENGTHB( i_wk_item_rec.item_code ) <> 7 ) THEN
        -- �i���R�[�h7���K�{�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00410          -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input_line_no        -- �g�[�N���R�[�h1
                      ,iv_token_value1 => i_wk_item_rec.line_no       -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_input_item_code      -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_item_rec.item_code     -- �g�[�N���l2
                     );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
      lv_step := 'A-4.6.2';
      -- �i���R�[�h�敪�`�F�b�N
-- Ver1.8  2009/05/18 Add  T1_0317 '5'�A'6'��o�^�\�ɕύX
--      IF ( SUBSTRB( i_wk_item_rec.item_code, 1, 1 ) NOT IN ( '0', '1', '2', '3' ) ) THEN
      IF ( SUBSTRB( i_wk_item_rec.item_code, 1, 1 ) NOT IN ( '0', '1', '2', '3', '5', '6' ) ) THEN
-- End
        -- �i���R�[�h�敪�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00411          -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input_line_no        -- �g�[�N���R�[�h1
                      ,iv_token_value1 => i_wk_item_rec.line_no       -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_input_item_code      -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_item_rec.item_code     -- �g�[�N���l2
                     );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
      lv_step := 'A-4.6.3';
      IF ( SUBSTRB( i_wk_item_rec.item_code, 1, 1) IN ( '0', '1' ) )
        AND ( SUBSTRB( i_wk_item_rec.item_code, 1, 2) NOT IN ( '00', '10' ) ) THEN
        -- �i���R�[�h�敪�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00411          -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input_line_no        -- �g�[�N���R�[�h1
                      ,iv_token_value1 => i_wk_item_rec.line_no       -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_input_item_code      -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_item_rec.item_code     -- �g�[�N���l2
                     );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
-- 2009/06/04 Ver1.10 ��QT1_1319 Add start
      lv_step := 'A-4.6.4';
      IF ( xxccp_common_pkg.chk_number( i_wk_item_rec.item_code ) <> TRUE ) THEN
        -- �i���R�[�h���l�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00474          -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input_line_no        -- �g�[�N���R�[�h1
                      ,iv_token_value1 => i_wk_item_rec.line_no       -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_input_item_code      -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_item_rec.item_code     -- �g�[�N���l2
                     );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
-- 2009/06/04 Ver1.10 ��QT1_1319 End
--
      --==============================================================
      -- A-4.7 �������`�F�b�N
      --==============================================================
      lv_step := 'A-4.7';
      -- �S�p�`�F�b�N
      IF ( xxccp_common_pkg.chk_double_byte( i_wk_item_rec.item_name ) <> TRUE ) THEN
        -- �S�p�`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00412          -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_item_name                -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_item_rec.item_name     -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no        -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_item_rec.line_no       -- �g�[�N���l3
                      ,iv_token_name4  => cv_tkn_input_item_code      -- �g�[�N���R�[�h4
                      ,iv_token_value4 => i_wk_item_rec.item_code     -- �g�[�N���l4
                     );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.8 ���̃`�F�b�N
      --==============================================================
      lv_step := 'A-4.8';
      -- �S�p�`�F�b�N
      IF ( xxccp_common_pkg.chk_double_byte( i_wk_item_rec.item_short_name ) <> TRUE ) THEN
        -- �S�p�`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00412                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_item_name                          -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_item_rec.item_short_name         -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_item_rec.line_no                 -- �g�[�N���l3
                      ,iv_token_name4  => cv_tkn_input_item_code                -- �g�[�N���R�[�h4
                      ,iv_token_value4 => i_wk_item_rec.item_code               -- �g�[�N���l4
                     );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.9 �J�i�`�F�b�N
      --==============================================================
      lv_step := 'A-4.9';
      -- ���p�`�F�b�N
-- Ver1.7  2009/04/10  Mod  ��QT1_0215 �Ή�
--ito->���ŏI�I�ɂ�xxccp_common_pkg�ɂȂ�\��
--      IF ( xxcmm_004common_pkg.chk_single_byte( i_wk_item_rec.item_name_alt ) <> TRUE ) THEN
      IF ( xxccp_common_pkg.chk_single_byte( i_wk_item_rec.item_name_alt ) <> TRUE ) THEN
-- End
        -- ���p�`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00413                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_item_name_alt                      -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_item_rec.item_name_alt           -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_item_rec.line_no                 -- �g�[�N���l3
                      ,iv_token_name4  => cv_tkn_input_item_code                -- �g�[�N���R�[�h4
                      ,iv_token_value4 => i_wk_item_rec.item_code               -- �g�[�N���l4
                     );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 add start by Shigeto.Niki
      --==============================================================
      -- A-4.10 ITF�R�[�h�`�F�b�N
      --==============================================================
      lv_step := 'A-4.10';
      -- ���p�`�F�b�N
      IF ( xxccp_common_pkg.chk_single_byte( i_wk_item_rec.itf_code ) <> TRUE ) THEN
        -- ���p�`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                  -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00413                  -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                        -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_itf_code                         -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                        -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_item_rec.itf_code              -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no                -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_item_rec.line_no               -- �g�[�N���l3
                      ,iv_token_name4  => cv_tkn_input_item_code              -- �g�[�N���R�[�h4
                      ,iv_token_value4 => i_wk_item_rec.item_code             -- �g�[�N���l4
                     );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.11 ���i���ރ`�F�b�N
      -- �{�o�^���K�{���ڂł͂Ȃ����߁A�l�������Ă���ꍇ�`�F�b�N���s���܂��B
      --==============================================================
      lv_step := 'A-4.11';
      IF ( i_wk_item_rec.product_class IS NOT NULL ) THEN
        -- LOOKUP�\���݃`�F�b�N
        -- ������
        l_lookup_rec := NULL;
        l_lookup_rec.lookup_type := cv_lookup_product_class;
        l_lookup_rec.lookup_code := i_wk_item_rec.product_class;
        l_lookup_rec.line_no     := i_wk_item_rec.line_no;
        l_lookup_rec.item_code   := i_wk_item_rec.item_code;
        -- LOOKUP�\���݃`�F�b�N
        chk_exists_lookup(
          io_lookup_rec => l_lookup_rec
         ,ov_errbuf     => lv_errbuf
         ,ov_retcode    => lv_retcode
         ,ov_errmsg     => lv_errmsg
        );
        -- �������ʃ`�F�b�N
        IF ( lv_retcode <> cv_status_normal ) THEN
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --
      --==============================================================
      -- A-4.12 �z���A�i���`�F�b�N
      --==============================================================
      lv_step := 'A-4.12.1';
      IF ( i_wk_item_rec.hon_product_class IS NOT NULL ) THEN
        -- �{�Џ��i�敪���u2:�h�����N�v�̏ꍇ�A�z���A�i���͕K�{�ƂȂ�܂��B
        IF ( TO_NUMBER(i_wk_item_rec.hon_product_class) = cn_hon_prod_drink ) THEN
          -- �z��,�i��
          IF (( i_wk_item_rec.palette_max_cs_qty IS NULL )
            OR ( i_wk_item_rec.palette_max_step_qty IS NULL )) THEN
            -- �{�Џ��i�敪�h�����N���K�{�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm                        -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_xxcmm_00416                        -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_input_line_no                      -- �g�[�N���R�[�h1
                          ,iv_token_value1 => i_wk_item_rec.line_no                     -- �g�[�N���l1
                          ,iv_token_name2  => cv_tkn_input_item_code                    -- �g�[�N���R�[�h2
                          ,iv_token_value2 => i_wk_item_rec.item_code                   -- �g�[�N���l2
                          ,iv_token_name3  => cv_tkn_cs_qty                             -- �g�[�N���R�[�h3
                          ,iv_token_value3 => i_wk_item_rec.palette_max_cs_qty          -- �g�[�N���l3
                          ,iv_token_name4  => cv_tkn_step_qty                           -- �g�[�N���R�[�h4
                          ,iv_token_value4 => i_wk_item_rec.palette_max_step_qty        -- �g�[�N���l4
                         );
            -- ���b�Z�[�W�o��
            xxcmm_004common_pkg.put_message(
              iv_message_buff => lv_errmsg
             ,ov_errbuf       => lv_errbuf
             ,ov_retcode      => lv_retcode
             ,ov_errmsg       => lv_errmsg
            );
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
      END IF;
      --
      lv_step := 'A-4.12.2';
      -- �z��
      -- �z����NOT NULL���A0�ȉ��̏ꍇ
      -- ���z����NULL�`�F�b�N�͌㑱�ōs�����߁A�����ł�NULL�`�F�b�N�͍s��Ȃ�
      IF    ( i_wk_item_rec.palette_max_cs_qty  IS NOT NULL)
        AND ( i_wk_item_rec.palette_max_cs_qty < 1 )
        AND ( i_wk_item_rec.hon_product_class = cn_hon_prod_drink)
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm               -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00493               -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                     -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_pale_max_cs_qty               -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                     -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_item_rec.palette_max_cs_qty -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no             -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_item_rec.line_no            -- �g�[�N���l3
                      ,iv_token_name4  => cv_tkn_input_item_code           -- �g�[�N���R�[�h4
                      ,iv_token_value4 => i_wk_item_rec.item_code          -- �g�[�N���l4
                     );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
      -- �i��
      -- �i����NOT NULL���A0�ȉ��̏ꍇ
      -- ���i����NULL�`�F�b�N�͌㑱�ōs�����߁A�����ł�NULL�`�F�b�N�͍s��Ȃ�
      IF    ( i_wk_item_rec.palette_max_step_qty  IS NOT NULL)
        AND ( i_wk_item_rec.palette_max_step_qty < 1 )
        AND ( i_wk_item_rec.hon_product_class = cn_hon_prod_drink)
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                 -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00493                 -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                       -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_pale_max_step_qty               -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                       -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_item_rec.palette_max_step_qty -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no               -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_item_rec.line_no              -- �g�[�N���l3
                      ,iv_token_name4  => cv_tkn_input_item_code             -- �g�[�N���R�[�h4
                      ,iv_token_value4 => i_wk_item_rec.item_code            -- �g�[�N���l4
                     );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.13 �d�ʁ^�̐σ`�F�b�N
      --==============================================================
      lv_step := 'A-4.13';
      IF ( i_wk_item_rec.weight_volume IS NULL ) THEN
        IF ( lv_required_item IS NULL ) THEN
          lv_required_item := cv_weight_volume;
        ELSE
          lv_required_item := lv_required_item || cv_msg_comma_double || cv_weight_volume;
        END IF;
      -- �d�ʁ^�̐ς�0�ȉ��̏ꍇ
      ELSIF ( i_wk_item_rec.weight_volume < 1 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm           -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00493           -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                 -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_weight_volume             -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                 -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_item_rec.weight_volume  -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no         -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_item_rec.line_no        -- �g�[�N���l3
                      ,iv_token_name4  => cv_tkn_input_item_code       -- �g�[�N���R�[�h4
                      ,iv_token_value4 => i_wk_item_rec.item_code      -- �g�[�N���l4
                     );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 add end by Shigeto.Niki
      --
-- Ver1.8  2009/05/18 Add  T1_0317 �i�ڃR�[�h�擪�P�o�C�g��'5'�܂���'6'�̏ꍇ�A2:���i ��ݒ�
--                         T1_0322 �q�i�ڂŏ��i���i�敪���o���ɐe�i�ڂ̏��i���i�敪�Ƃ̔�r������ǉ�
      --==============================================================
      -- A-4.16 ���i���i�敪�`�F�b�N
      -- �e�i�ڎ��`�F�b�N(�q�i�ڂ͐e�l�p��)
      -- 2009/05/15 �ǋL
      --  �q�i�ڂ͐e�l���p�������邪�A���[���ʂ�ݒ肳���K�v����
      --  ���o�������i���i�敪�Ɛe�i�ڂ̏��i���i�敪���قȂ�ꍇ�G���[�Ƃ���
      --==============================================================
      lv_step := 'A-4.16';
      -- �i�ڃR�[�h�̌n�ŏ��i���i�敪�l��ύX���܂��B
      IF ( SUBSTRB(i_wk_item_rec.item_code, 1, 2 ) = '00' ) THEN
        lv_category_val := TO_CHAR(cn_item_prod_prod);
      ELSIF ( SUBSTRB(i_wk_item_rec.item_code, 1, 2 ) = '10' ) THEN
        lv_category_val := TO_CHAR(cn_item_prod_item);
      -- �i�ڃR�[�h�擪�P�o�C�g��'5'�܂���'6'�̏ꍇ�A2:���i ��ݒ�
      ELSIF ( SUBSTRB(i_wk_item_rec.item_code, 1, 1 ) IN ( '5', '6' ) ) THEN
        lv_category_val := TO_CHAR(cn_item_prod_prod);
      ELSE
        lv_category_val := NULL;
      END IF;
-- End
      --
      --==============================================================
      -- �e�i�ڎ�
      -- �q�i�ڂ̏ꍇ�A�e�l�p�����ڂ̓`�F�b�N���܂���B
      --==============================================================
      IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
        --==============================================================
        -- A-4.14 ����Ώۃ`�F�b�N
        -- �e�i�ڎ��`�F�b�N(�q�i�ڂ͖������Łu0:����ΏۊO�v�ƂȂ邽�߃`�F�b�N���܂���B)
        --==============================================================
        lv_step := 'A-4.14.1';
        IF ( i_wk_item_rec.sales_target_flag IS NOT NULL ) THEN
          -- ������
          l_lookup_rec := NULL;
          l_lookup_rec.lookup_type := cv_lookup_sales_target;
          l_lookup_rec.lookup_code := i_wk_item_rec.sales_target_flag;
          l_lookup_rec.line_no     := i_wk_item_rec.line_no;
          l_lookup_rec.item_code   := i_wk_item_rec.item_code;
          -- LOOKUP�\���݃`�F�b�N
          chk_exists_lookup(
            io_lookup_rec => l_lookup_rec
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          );
          -- �������ʃ`�F�b�N
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          END IF;
          --
          lv_step := 'A-4.14.2';
          -- ����Ώۂ�LOOKUP�\���ݎ�
          IF ( lv_retcode = cv_status_normal ) THEN
            -- ����Ώۂ��u1:����Ώہv�̏ꍇ�A���敪���u1:���v�Z�v�̓G���[�`�F�b�N
            IF ( i_wk_item_rec.sales_target_flag = cv_sales_target_1 ) THEN
              IF ( i_wk_item_rec.rate_class = cn_rate_class_1 ) THEN
                -- ����Ώێ����敪�G���[
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_msg_xxcmm_00414            -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1  => cv_tkn_input_line_no          -- �g�[�N���R�[�h1
                              ,iv_token_value1 => i_wk_item_rec.line_no         -- �g�[�N���l1
                              ,iv_token_name2  => cv_tkn_input_item_code        -- �g�[�N���R�[�h2
                              ,iv_token_value2 => i_wk_item_rec.item_code       -- �g�[�N���l2
                             );
                -- ���b�Z�[�W�o��
                xxcmm_004common_pkg.put_message(
                  iv_message_buff => lv_errmsg
                 ,ov_errbuf       => lv_errbuf
                 ,ov_retcode      => lv_retcode
                 ,ov_errmsg       => lv_errmsg
                );
                lv_check_flag := cv_status_error;
              END IF;
            END IF;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.15 ��P�ʃ`�F�b�N
        -- �e�i�ڎ��`�F�b�N(�q�i�ڂ͐e�l�p��)
        --==============================================================
        lv_step := 'A-4.15';
        IF ( i_wk_item_rec.item_um IS NOT NULL ) THEN
-- 2009/09/07 Ver1.15 ��Q0000948 modify start by Y.Kuboshima
--          -- �{�Akg�ȊO�̓G���[
--          IF ( i_wk_item_rec.item_um NOT IN ( cn_item_um_hon, cn_item_um_kg ) ) THEN
          -- ��P�ʒǉ��̂��߁ALOOKUP(XXCMM_UNITS_OF_MEASURE)�ɑ��݂��Ȃ��ꍇ�G���[�Ƃ���悤�ɏC��
          -- ��P�ʑ��݃`�F�b�N
          SELECT COUNT(1)
          INTO   ln_chk_stand_unit
          FROM   fnd_lookup_values_vl flvv
          WHERE  flvv.lookup_type  = cv_lookup_units_of_measure
            AND  flvv.enabled_flag = cv_yes
            AND  flvv.meaning      = i_wk_item_rec.item_um;
          -- ��P�ʂ����݂��Ȃ��ꍇ
          IF ( ln_chk_stand_unit = 0 ) THEN
-- 2009/09/07 Ver1.15 ��Q0000948 modify end by Y.Kuboshima
            -- ��P�ʃG���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm                -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_xxcmm_00415                -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_item_um                    -- �g�[�N���R�[�h1
                          ,iv_token_value1 => i_wk_item_rec.item_um             -- �g�[�N���l1
                          ,iv_token_name2  => cv_tkn_input_line_no              -- �g�[�N���R�[�h2
                          ,iv_token_value2 => i_wk_item_rec.line_no             -- �g�[�N���l2
                          ,iv_token_name3  => cv_tkn_input_item_code            -- �g�[�N���R�[�h3
                          ,iv_token_value3 => i_wk_item_rec.item_code           -- �g�[�N���l3
                         );
            -- ���b�Z�[�W�o��
            xxcmm_004common_pkg.put_message(
              iv_message_buff => lv_errmsg
             ,ov_errbuf       => lv_errbuf
             ,ov_retcode      => lv_retcode
             ,ov_errmsg       => lv_errmsg
            );
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
        --
-- Ver1.8  2009/05/18 Del  T1_0322 �q�i�ڎ������i���i�敪�𓱏o����悤�C���̂��ߍ폜
        --==============================================================
        -- A-4.12 ���i���i�敪�`�F�b�N
        -- �e�i�ڎ��`�F�b�N(�q�i�ڂ͐e�l�p��)
        --=============================================================
--      ���o�����́A�e�i�ڗp�`�F�b�N�����̑O�Ɉړ����܂����B
--        lv_step := 'A-4.12';
--        IF ( i_wk_item_rec.item_product_class IS NOT NULL ) THEN
--          -- ���i���i�敪����ϐ��ɃZ�b�g
--          l_item_ctg_rec.category_set_name := cv_categ_set_item_prod;
----20090212 Mod START
--          -- �i�ڃR�[�h�̌n�ŏ��i���i�敪�l��ύX���܂��B
--          IF ( SUBSTRB(i_wk_item_rec.item_code, 1, 2 ) = '00' ) THEN
--            lv_category_val := TO_CHAR(cn_item_prod_prod);
--          ELSIF ( SUBSTRB(i_wk_item_rec.item_code, 1, 2 ) = '10' ) THEN
--            lv_category_val := TO_CHAR(cn_item_prod_item);
---- Ver1.4 20090218 Mod START
--          ELSE
--            lv_category_val := i_wk_item_rec.item_product_class;
---- Ver1.4 20090218 Mod END
--          END IF;
--
-- End
--
-- Ver1.8  2009/05/18 Add  T1_0322 ���i���i�敪�����o���̏�����ǉ�
          IF ( lv_category_val IS NULL ) THEN
            lv_category_val := i_wk_item_rec.item_product_class;
          END IF;
          --
          l_item_ctg_rec.category_set_name := cv_categ_set_item_prod;
-- End
--          l_item_ctg_rec.category_val      := i_wk_item_rec.item_product_class;
          l_item_ctg_rec.category_val      := lv_category_val;
-- Ver1.8  2009/05/19  �o�O�H�H  �㏑�����ꂽ���i���i�敪������悤�C��
          -- ���i���i�敪�l��ݒ�
          lv_p_item_prod_class             := lv_category_val;
-- End

--20090212 Mod END
          l_item_ctg_rec.line_no           := i_wk_item_rec.line_no;
          l_item_ctg_rec.item_code         := i_wk_item_rec.item_code;
          --
          -- �J�e�S�����݃`�F�b�N
          chk_exists_category(
            io_item_ctg_rec => l_item_ctg_rec
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          -- �������ʃ`�F�b�N
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          END IF;
-- Ver1.8  2009/05/18 Del  T1_0322 �폜
--        END IF;
-- End
        --
        --==============================================================
        -- A-4.17 ���敪�`�F�b�N
        -- �e�i�ڎ��`�F�b�N(�q�i�ڂ͐e�l�p��)
        --==============================================================
        lv_step := 'A-4.17';
        IF ( i_wk_item_rec.rate_class IS NOT NULL ) THEN
          -- LOOKUP�\���݃`�F�b�N
          -- ������
          l_lookup_rec := NULL;
          l_lookup_rec.lookup_type := cv_lookup_rate_class;
          l_lookup_rec.lookup_code := i_wk_item_rec.rate_class;
          l_lookup_rec.line_no     := i_wk_item_rec.line_no;
          l_lookup_rec.item_code   := i_wk_item_rec.item_code;
          -- LOOKUP�\���݃`�F�b�N
          chk_exists_lookup(
            io_lookup_rec => l_lookup_rec
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          );
          -- �������ʃ`�F�b�N
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.18 ���e�ʒP�ʃ`�F�b�N
        -- �e�i�ڎ��`�F�b�N(�q�i�ڂ͐e�l�p��)
        --==============================================================
        lv_step := 'A-4.18';
        IF ( i_wk_item_rec.nets_uom_code IS NOT NULL ) THEN
          -- LOOKUP�\���݃`�F�b�N
          -- ������
          l_lookup_rec := NULL;
          l_lookup_rec.lookup_type := cv_lookup_nets_uom_code;
          l_lookup_rec.meaning     := i_wk_item_rec.nets_uom_code;
          l_lookup_rec.line_no     := i_wk_item_rec.line_no;
          l_lookup_rec.item_code   := i_wk_item_rec.item_code;
          -- LOOKUP�\���݃`�F�b�N
          chk_exists_lookup(
            io_lookup_rec => l_lookup_rec
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          );
          -- �������ʃ`�F�b�N
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          ELSE
            -- ���e�ʒP�ʂ�߂��܂��B(�e�i�ڂ̏ꍇ�̂ݒl�������Ă�����)
            o_etc_rec.nets_uom_code := l_lookup_rec.lookup_code;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.19 �{�Џ��i�敪�`�F�b�N
        -- �e�i�ڎ��`�F�b�N(�q�i�ڂ͐e�l�p��)
        --==============================================================
        lv_step := 'A-4.19';        
        IF ( i_wk_item_rec.hon_product_class IS NOT NULL ) THEN
          -- �{�Џ��i�敪����ϐ��ɃZ�b�g
          l_item_ctg_rec.category_set_name := cv_categ_set_hon_prod;
          l_item_ctg_rec.category_val      := i_wk_item_rec.hon_product_class;
          -- �J�e�S�����݃`�F�b�N
          chk_exists_category(
            io_item_ctg_rec => l_item_ctg_rec
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          -- �������ʃ`�F�b�N
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.20 �o�����敪�`�F�b�N
        -- �e�i�ڎ��`�F�b�N(�q�i�ڂ͐e�l�p��)
        -- �{�Џ��i�敪�u1:���[�t�v�̏ꍇ�`�F�b�N���܂��B���u2:�h�����N�v�̏ꍇ�́u0:���̑��v���Z�b�g���܂��B
        --==============================================================
        lv_step := 'A-4.20';
        IF ( i_wk_item_rec.hon_product_class IS NOT NULL ) THEN
          IF ( TO_NUMBER(i_wk_item_rec.hon_product_class) = cn_hon_prod_leaf ) THEN
            IF ( i_wk_item_rec.baracha_div IS NOT NULL ) THEN
              -- LOOKUP�\���݃`�F�b�N
              -- ������
              l_lookup_rec := NULL;
              l_lookup_rec.lookup_type := cv_lookup_barachakubun;
              l_lookup_rec.lookup_code := i_wk_item_rec.baracha_div;
              l_lookup_rec.line_no     := i_wk_item_rec.line_no;
              l_lookup_rec.item_code   := i_wk_item_rec.item_code;
              -- LOOKUP�\���݃`�F�b�N
              chk_exists_lookup(
                io_lookup_rec => l_lookup_rec
               ,ov_errbuf     => lv_errbuf
               ,ov_retcode    => lv_retcode
               ,ov_errmsg     => lv_errmsg
              );
              -- �������ʃ`�F�b�N
              IF ( lv_retcode <> cv_status_normal ) THEN
                lv_check_flag := cv_status_error;
              END IF;
            END IF;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.21 JAN�R�[�h�`�F�b�N
        -- �e�i�ڎ��`�F�b�N(�q�i�ڂ͐e�l�p��)
        --==============================================================
        lv_step := 'A-4.21';
        -- ���p�`�F�b�N
-- Ver1.7  2009/04/10  Mod  ��QT1_0215 �Ή�
--ito->���ŏI�I�ɂ�xxccp_common_pkg�ɂȂ�\��
--        IF ( xxcmm_004common_pkg.chk_single_byte( i_wk_item_rec.jan_code ) <> TRUE ) THEN
        IF ( xxccp_common_pkg.chk_single_byte( i_wk_item_rec.jan_code ) <> TRUE ) THEN
-- End
          -- ���p�`�F�b�N�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_00413                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_jan_code                           -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_item_rec.jan_code                -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_item_rec.line_no                 -- �g�[�N���l3
                        ,iv_token_name4  => cv_tkn_input_item_code                -- �g�[�N���R�[�h4
                        ,iv_token_value4 => i_wk_item_rec.item_code               -- �g�[�N���l4
                       );
          -- ���b�Z�[�W�o��
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          lv_check_flag := cv_status_error;
        END IF;
        --
        --==============================================================
        -- A-4.22 �P�[�XJAN�R�[�h�`�F�b�N
        -- �e�i�ڎ��`�F�b�N(�q�i�ڂ͐e�l�p��)
        --==============================================================
        lv_step := 'A-4.22';
        -- ���p�`�F�b�N
-- Ver1.7  2009/04/10  Mod  ��QT1_0215 �Ή�
--ito->���ŏI�I�ɂ�xxccp_common_pkg�ɂȂ�\��
--        IF ( xxcmm_004common_pkg.chk_single_byte( i_wk_item_rec.case_jan_code ) <> TRUE ) THEN
        IF ( xxccp_common_pkg.chk_single_byte( i_wk_item_rec.case_jan_code ) <> TRUE ) THEN
-- End
          -- ���p�`�F�b�N�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                  -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_00413                  -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                        -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_case_jan_code                    -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                        -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_item_rec.case_jan_code         -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_item_rec.line_no               -- �g�[�N���l3
                        ,iv_token_name4  => cv_tkn_input_item_code              -- �g�[�N���R�[�h4
                        ,iv_token_value4 => i_wk_item_rec.item_code             -- �g�[�N���l4
                       );
          -- ���b�Z�[�W�o��
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          lv_check_flag := cv_status_error;
        END IF;
        --
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete start by Shigeto.Niki
--        --==============================================================
--        -- A-4.19 ITF�R�[�h�`�F�b�N
--        -- �e�i�ڎ��`�F�b�N(�q�i�ڂ͐e�l�p��)
--        --==============================================================
--        lv_step := 'A-4.19';
--        -- ���p�`�F�b�N
---- Ver1.7  2009/04/10  Mod  ��QT1_0215 �Ή�
----ito->���ŏI�I�ɂ�xxccp_common_pkg�ɂȂ�\��
----        IF ( xxcmm_004common_pkg.chk_single_byte( i_wk_item_rec.itf_code ) <> TRUE ) THEN
--        IF ( xxccp_common_pkg.chk_single_byte( i_wk_item_rec.itf_code ) <> TRUE ) THEN
---- End
--          -- ���p�`�F�b�N�G���[
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_appl_name_xxcmm                  -- �A�v���P�[�V�����Z�k��
--                        ,iv_name         => cv_msg_xxcmm_00413                  -- ���b�Z�[�W�R�[�h
--                        ,iv_token_name1  => cv_tkn_input                        -- �g�[�N���R�[�h1
--                        ,iv_token_value1 => cv_itf_code                         -- �g�[�N���l1
--                        ,iv_token_name2  => cv_tkn_value                        -- �g�[�N���R�[�h2
--                        ,iv_token_value2 => i_wk_item_rec.itf_code              -- �g�[�N���l2
--                        ,iv_token_name3  => cv_tkn_input_line_no                -- �g�[�N���R�[�h3
--                        ,iv_token_value3 => i_wk_item_rec.line_no               -- �g�[�N���l3
--                        ,iv_token_name4  => cv_tkn_input_item_code              -- �g�[�N���R�[�h4
--                        ,iv_token_value4 => i_wk_item_rec.item_code             -- �g�[�N���l4
--                       );
--          -- ���b�Z�[�W�o��
--          xxcmm_004common_pkg.put_message(
--            iv_message_buff => lv_errmsg
--           ,ov_errbuf       => lv_errbuf
--           ,ov_retcode      => lv_retcode
--           ,ov_errmsg       => lv_errmsg
--          );
--          lv_check_flag := cv_status_error;
--        END IF;
--        --
--        --==============================================================
--        -- A-4.20 ���i���ރ`�F�b�N
--        -- �e�i�ڎ��`�F�b�N(�q�i�ڂ͐e�l�p��)
--        -- �{�o�^���K�{���ڂł͂Ȃ����߁A�l�������Ă���ꍇ�`�F�b�N���s���܂��B
--        --==============================================================
--        lv_step := 'A-4.20';
--        IF ( i_wk_item_rec.product_class IS NOT NULL ) THEN
--          -- LOOKUP�\���݃`�F�b�N
--          -- ������
--          l_lookup_rec := NULL;
--          l_lookup_rec.lookup_type := cv_lookup_product_class;
--          l_lookup_rec.lookup_code := i_wk_item_rec.product_class;
--          l_lookup_rec.line_no     := i_wk_item_rec.line_no;
--          l_lookup_rec.item_code   := i_wk_item_rec.item_code;
--          -- LOOKUP�\���݃`�F�b�N
--          chk_exists_lookup(
--            io_lookup_rec => l_lookup_rec
--           ,ov_errbuf     => lv_errbuf
--           ,ov_retcode    => lv_retcode
--           ,ov_errmsg     => lv_errmsg
--          );
--          -- �������ʃ`�F�b�N
--          IF ( lv_retcode <> cv_status_normal ) THEN
--            lv_check_flag := cv_status_error;
--          END IF;
--        END IF;
--        --
--        --==============================================================
--        -- A-4.21 �z���A�i���`�F�b�N
--        -- �e�i�ڎ��`�F�b�N(�q�i�ڂ͐e�l�p��)
--        --==============================================================
--        lv_step := 'A-4.21';
--        IF ( i_wk_item_rec.hon_product_class IS NOT NULL ) THEN
--          -- �{�Џ��i�敪���u2:�h�����N�v�̏ꍇ�A�z���A�i���͕K�{�ƂȂ�܂��B
--          IF ( TO_NUMBER(i_wk_item_rec.hon_product_class) = cn_hon_prod_drink ) THEN
--            -- �z��,�i��
--            IF (( i_wk_item_rec.palette_max_cs_qty IS NULL )
--              OR ( i_wk_item_rec.palette_max_step_qty IS NULL )) THEN
--              -- �{�Џ��i�敪�h�����N���K�{�G���[
--              lv_errmsg := xxccp_common_pkg.get_msg(
--                             iv_application  => cv_appl_name_xxcmm                        -- �A�v���P�[�V�����Z�k��
--                            ,iv_name         => cv_msg_xxcmm_00416                        -- ���b�Z�[�W�R�[�h
--                            ,iv_token_name1  => cv_tkn_input_line_no                      -- �g�[�N���R�[�h1
--                            ,iv_token_value1 => i_wk_item_rec.line_no                     -- �g�[�N���l1
--                            ,iv_token_name2  => cv_tkn_input_item_code                    -- �g�[�N���R�[�h2
--                            ,iv_token_value2 => i_wk_item_rec.item_code                   -- �g�[�N���l2
--                            ,iv_token_name3  => cv_tkn_cs_qty                             -- �g�[�N���R�[�h3
--                            ,iv_token_value3 => i_wk_item_rec.palette_max_cs_qty          -- �g�[�N���l3
--                            ,iv_token_name4  => cv_tkn_step_qty                           -- �g�[�N���R�[�h4
--                            ,iv_token_value4 => i_wk_item_rec.palette_max_step_qty        -- �g�[�N���l4
--                           );
--              -- ���b�Z�[�W�o��
--              xxcmm_004common_pkg.put_message(
--                iv_message_buff => lv_errmsg
--               ,ov_errbuf       => lv_errbuf
--               ,ov_retcode      => lv_retcode
--               ,ov_errmsg       => lv_errmsg
--              );
--              lv_check_flag := cv_status_error;
--            END IF;
--          END IF;
--        END IF;
-- 2010/01/04 Ver1.18 ��QE_�{�ғ�_00614 delete end by Shigeto.Niki
        --
        --==============================================================
        -- A-4.23 ����Q�`�F�b�N
        -- �e�i�ڎ��`�F�b�N(�q�i�ڂ͐e�l�p��)
        --==============================================================
        lv_step := 'A-4.23';
        IF ( i_wk_item_rec.policy_group IS NOT NULL ) THEN
          -- ����Q����ϐ��ɃZ�b�g
          l_item_ctg_rec.category_set_name := cv_categ_set_seisakugun;
          l_item_ctg_rec.category_val      := i_wk_item_rec.policy_group;
          -- �J�e�S�����݃`�F�b�N
          chk_exists_category(
            io_item_ctg_rec => l_item_ctg_rec
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          --
          -- �������ʃ`�F�b�N
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.24 �e��Q�`�F�b�N
        -- �e�i�ڎ��`�F�b�N(�q�i�ڂ͐e�l�p��)
        -- �{�o�^���K�{���ڂł͂Ȃ����߁A�l�������Ă���ꍇ�`�F�b�N���s���܂��B
        --==============================================================
        lv_step := 'A-4.24';
        IF ( i_wk_item_rec.vessel_group IS NOT NULL ) THEN
          -- LOOKUP�\���݃`�F�b�N
          -- ������
          l_lookup_rec := NULL;
          l_lookup_rec.lookup_type := cv_lookup_vessel_group;
          l_lookup_rec.lookup_code := i_wk_item_rec.vessel_group;
          l_lookup_rec.line_no     := i_wk_item_rec.line_no;
          l_lookup_rec.item_code   := i_wk_item_rec.item_code;
          -- LOOKUP�\���݃`�F�b�N
          chk_exists_lookup(
            io_lookup_rec => l_lookup_rec
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          );
          -- �������ʃ`�F�b�N
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.25 �V���i�敪�`�F�b�N
        -- �e�i�ڎ��`�F�b�N(�q�i�ڂ͐e�l�p��)
        -- �{�o�^���K�{���ڂł͂Ȃ����߁A�l�������Ă���ꍇ�`�F�b�N���s���܂��B
        --==============================================================
        lv_step := 'A-4.25';
        IF ( i_wk_item_rec.new_item_div IS NOT NULL ) THEN
          -- LOOKUP�\���݃`�F�b�N
          -- ������
          l_lookup_rec := NULL;
          l_lookup_rec.lookup_type := cv_lookup_new_item_div;
          l_lookup_rec.lookup_code := i_wk_item_rec.new_item_div;
          l_lookup_rec.line_no     := i_wk_item_rec.line_no;
          l_lookup_rec.item_code   := i_wk_item_rec.item_code;
          -- LOOKUP�\���݃`�F�b�N
          chk_exists_lookup(
            io_lookup_rec => l_lookup_rec
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          );
          -- �������ʃ`�F�b�N
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.26 �o���Q�`�F�b�N
        -- �e�i�ڎ��`�F�b�N(�q�i�ڂ͐e�l�p��)
        -- �{�o�^���K�{���ڂł͂Ȃ����߁A�l�������Ă���ꍇ�`�F�b�N���s���܂��B
        --==============================================================
        lv_step := 'A-4.26';
        IF ( i_wk_item_rec.acnt_group IS NOT NULL ) THEN
          -- LOOKUP�\���݃`�F�b�N
          -- ������
          l_lookup_rec := NULL;
          l_lookup_rec.lookup_type := cv_lookup_acnt_group;
          l_lookup_rec.lookup_code := i_wk_item_rec.acnt_group;
          l_lookup_rec.line_no     := i_wk_item_rec.line_no;
          l_lookup_rec.item_code   := i_wk_item_rec.item_code;
          -- LOOKUP�\���݃`�F�b�N
          chk_exists_lookup(
            io_lookup_rec => l_lookup_rec
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          );
          -- �������ʃ`�F�b�N
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.27 �o���e��Q�`�F�b�N
        -- �e�i�ڎ��`�F�b�N(�q�i�ڂ͐e�l�p��)
        -- �{�o�^���K�{���ڂł͂Ȃ����߁A�l�������Ă���ꍇ�`�F�b�N���s���܂��B
        --==============================================================
        lv_step := 'A-4.27';
        IF ( i_wk_item_rec.acnt_vessel_group IS NOT NULL ) THEN
          -- LOOKUP�\���݃`�F�b�N
          -- ������
          l_lookup_rec := NULL;
          l_lookup_rec.lookup_type := cv_lookup_acnt_vessel_group;
          l_lookup_rec.lookup_code := i_wk_item_rec.acnt_vessel_group;
          l_lookup_rec.line_no     := i_wk_item_rec.line_no;
          l_lookup_rec.item_code   := i_wk_item_rec.item_code;
          -- LOOKUP�\���݃`�F�b�N
          chk_exists_lookup(
            io_lookup_rec => l_lookup_rec
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          );
          -- �������ʃ`�F�b�N
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.28 �u�����h�Q�`�F�b�N
        -- �e�i�ڎ��`�F�b�N(�q�i�ڂ͐e�l�p��)
        -- �{�o�^���K�{���ڂł͂Ȃ����߁A�l�������Ă���ꍇ�`�F�b�N���s���܂��B
        --==============================================================
        lv_step := 'A-4.28';
        IF ( i_wk_item_rec.brand_group IS NOT NULL ) THEN
          -- LOOKUP�\���݃`�F�b�N
          -- ������
          l_lookup_rec := NULL;
          l_lookup_rec.lookup_type := cv_lookup_brand_group;
          l_lookup_rec.lookup_code := i_wk_item_rec.brand_group;
          l_lookup_rec.line_no     := i_wk_item_rec.line_no;
          l_lookup_rec.item_code   := i_wk_item_rec.item_code;
          -- LOOKUP�\���݃`�F�b�N
          chk_exists_lookup(
            io_lookup_rec => l_lookup_rec
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          );
          -- �������ʃ`�F�b�N
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.29 �W�������`�F�b�N
        -- �e�i�ڎ��`�F�b�N(�q�i�ڂ͐e�l�p��)
        --==============================================================
        lv_step := 'A-4.29';
        -- 7�̍��v�l�������łȂ��ꍇ�̓G���[�Ƃ��܂��B
        IF   ( i_wk_item_rec.standard_price_1 IS NOT NULL )
          OR ( i_wk_item_rec.standard_price_2 IS NOT NULL )
          OR ( i_wk_item_rec.standard_price_3 IS NOT NULL )
          OR ( i_wk_item_rec.standard_price_4 IS NOT NULL )
          OR ( i_wk_item_rec.standard_price_5 IS NOT NULL )
          OR ( i_wk_item_rec.standard_price_6 IS NOT NULL )
          OR ( i_wk_item_rec.standard_price_7 IS NOT NULL ) THEN
          ln_opm_cost_total := NVL(TO_NUMBER(i_wk_item_rec.standard_price_1), 0) +
                               NVL(TO_NUMBER(i_wk_item_rec.standard_price_2), 0) +
                               NVL(TO_NUMBER(i_wk_item_rec.standard_price_3), 0) +
                               NVL(TO_NUMBER(i_wk_item_rec.standard_price_4), 0) +
                               NVL(TO_NUMBER(i_wk_item_rec.standard_price_5), 0) +
                               NVL(TO_NUMBER(i_wk_item_rec.standard_price_6), 0) +
                               NVL(TO_NUMBER(i_wk_item_rec.standard_price_7), 0);
-- 2009/08/07 Ver1.14 ��Q0000862 modify start by Y.Kuboshima
--          IF ( ln_opm_cost_total <> TRUNC(ln_opm_cost_total) ) THEN
--            -- �W�������G���[
--            lv_errmsg := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_appl_name_xxcmm                          -- �A�v���P�[�V�����Z�k��
--                          ,iv_name         => cv_msg_xxcmm_00438                          -- ���b�Z�[�W�R�[�h
--                          ,iv_token_name1  => cv_tkn_opm_cost                             -- �g�[�N���R�[�h1
--                          ,iv_token_value1 => ln_opm_cost_total                           -- �g�[�N���l1
--                          ,iv_token_name2  => cv_tkn_input_line_no                        -- �g�[�N���R�[�h1
--                          ,iv_token_value2 => i_wk_item_rec.line_no                       -- �g�[�N���l1
--                          ,iv_token_name3  => cv_tkn_input_item_code                      -- �g�[�N���R�[�h2
--                          ,iv_token_value3 => i_wk_item_rec.item_code                     -- �g�[�N���l2
--                         );
--            -- ���b�Z�[�W�o��
--            xxcmm_004common_pkg.put_message(
--              iv_message_buff => lv_errmsg
--             ,ov_errbuf       => lv_errbuf
--             ,ov_retcode      => lv_retcode
--             ,ov_errmsg       => lv_errmsg
--            );
--            lv_check_flag := cv_status_error;
--          END IF;
          --
          -- ���ޕi��(�i���R�[�h�̈ꌅ�ڂ�'5','6')�̏ꍇ
          IF ( SUBSTRB( i_wk_item_rec.item_code, 1, 1) IN ( cv_leaf_material, cv_drink_material ) ) THEN
            -- �W���������v�l�������_�O���ȏ�̏ꍇ
            IF ( ln_opm_cost_total <> TRUNC( ln_opm_cost_total, 2 ) ) THEN
              -- �W�������G���[
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_name_xxcmm                          -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_msg_xxcmm_00438                          -- ���b�Z�[�W�R�[�h
                            ,iv_token_name1  => cv_tkn_opm_cost                             -- �g�[�N���R�[�h1
                            ,iv_token_value1 => ln_opm_cost_total                           -- �g�[�N���l1
                            ,iv_token_name2  => cv_tkn_input_line_no                        -- �g�[�N���R�[�h1
                            ,iv_token_value2 => i_wk_item_rec.line_no                       -- �g�[�N���l1
                            ,iv_token_name3  => cv_tkn_input_item_code                      -- �g�[�N���R�[�h2
                            ,iv_token_value3 => i_wk_item_rec.item_code                     -- �g�[�N���l2
                           );
              -- ���b�Z�[�W�o��
              xxcmm_004common_pkg.put_message(
                iv_message_buff => lv_errmsg
               ,ov_errbuf       => lv_errbuf
               ,ov_retcode      => lv_retcode
               ,ov_errmsg       => lv_errmsg
              );
              lv_check_flag := cv_status_error;
            END IF;
          -- ���ޕi�ڈȊO�̏ꍇ
          ELSE
            -- �����_���܂܂�Ă���ꍇ
            IF ( ln_opm_cost_total <> TRUNC(ln_opm_cost_total) ) THEN
              -- �W�������G���[
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_name_xxcmm                          -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_msg_xxcmm_00438                          -- ���b�Z�[�W�R�[�h
                            ,iv_token_name1  => cv_tkn_opm_cost                             -- �g�[�N���R�[�h1
                            ,iv_token_value1 => ln_opm_cost_total                           -- �g�[�N���l1
                            ,iv_token_name2  => cv_tkn_input_line_no                        -- �g�[�N���R�[�h1
                            ,iv_token_value2 => i_wk_item_rec.line_no                       -- �g�[�N���l1
                            ,iv_token_name3  => cv_tkn_input_item_code                      -- �g�[�N���R�[�h2
                            ,iv_token_value3 => i_wk_item_rec.item_code                     -- �g�[�N���l2
                           );
              -- ���b�Z�[�W�o��
              xxcmm_004common_pkg.put_message(
                iv_message_buff => lv_errmsg
               ,ov_errbuf       => lv_errbuf
               ,ov_retcode      => lv_retcode
               ,ov_errmsg       => lv_errmsg
              );
              lv_check_flag := cv_status_error;
            END IF;
          END IF;
-- 2009/08/07 Ver1.14 ��Q0000862 modify start by Y.Kuboshima
          --
--Ver1.12  2009/07/07  Add  �W�������v�Ɖc�ƌ����̔�r������ǉ�
          -- �c�ƌ����v >= �c�ƌ����̏ꍇ
          IF ( ln_opm_cost_total > TO_NUMBER( NVL( i_wk_item_rec.business_price, 0 ))) THEN
            -- �W�������G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm                          -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_xxcmm_00434                          -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_disc_cost                            -- �g�[�N���R�[�h1
                          ,iv_token_value1 => i_wk_item_rec.business_price                -- �g�[�N���l1
                          ,iv_token_name2  => cv_tkn_opm_cost                             -- �g�[�N���R�[�h2
                          ,iv_token_value2 => TO_CHAR( ln_opm_cost_total )                -- �g�[�N���l2
                          ,iv_token_name3  => cv_tkn_input_line_no                        -- �g�[�N���R�[�h3
                          ,iv_token_value3 => i_wk_item_rec.line_no                       -- �g�[�N���l3
                          ,iv_token_name4  => cv_tkn_input_item_code                      -- �g�[�N���R�[�h4
                          ,iv_token_value4 => i_wk_item_rec.item_code                     -- �g�[�N���l4
                         );
            -- ���b�Z�[�W�o��
            xxcmm_004common_pkg.put_message(
              iv_message_buff => lv_errmsg
             ,ov_errbuf       => lv_errbuf
             ,ov_retcode      => lv_retcode
             ,ov_errmsg       => lv_errmsg
            );
            lv_check_flag := cv_status_error;
          END IF;
--End1.12
          --
        END IF;
-- Ver1.8  2009/05/18 Add  T1_0322 �q�i�ڂŏ��i���i�敪���o���ɐe�i�ڂ̏��i���i�敪�Ƃ̔�r������ǉ�
      ELSE
        --==============================================================
        -- A-4.32 ���i���i�敪�`�F�b�N
        --==============================================================
        -- �q�i�ڎ��̃`�F�b�N����
        -- ���i���i�敪���i�ڃR�[�h�ɂ���ē��o����Ă���ꍇ
        lv_step := 'A-4.32.1';
        IF ( lv_category_val IS NOT NULL ) THEN
          lv_step := 'A-4.32.2';
          ----------------------------------------------------
          -- ���o�������i���i�敪�Ɛe�̐��i���i�敪���r
          ----------------------------------------------------
          -- �e�i�ڂ̏��i���i�敪���擾
          SELECT    mcssk.segment1        item_product_class
          INTO      lv_p_item_prod_class
          FROM      gmi_item_categories   gicssk
                   ,ic_item_mst_b         iimb
                   ,mtl_category_sets_vl  mcsssk
                   ,mtl_categories_vl     mcssk
          WHERE     mcsssk.category_set_name  = cv_categ_set_item_prod          -- ���i���i�敪
          AND       iimb.item_no              = i_wk_item_rec.parent_item_code  -- �e�i�ڃR�[�h
          AND       gicssk.category_set_id    = mcsssk.category_set_id          -- �J�e�S���Z�b�g
          AND       gicssk.item_id            = iimb.item_id                    -- �i�ڂh�c
          AND       gicssk.category_id        = mcssk.category_id;              -- �J�e�S���h�c
          --
          -- ���i���i�敪�̔�r
          IF ( lv_category_val != lv_p_item_prod_class ) THEN
            -- �e�ƈقȂ鏤�i���i�敪�̏ꍇ�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm                          -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_xxcmm_00431                          -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_input_line_no                        -- �g�[�N���R�[�h1
                          ,iv_token_value1 => i_wk_item_rec.line_no                       -- �g�[�N���l1
                          ,iv_token_name2  => cv_tkn_input_item_code                      -- �g�[�N���R�[�h2
                          ,iv_token_value2 => i_wk_item_rec.item_code                     -- �g�[�N���l2
                          ,iv_token_name3  => cv_tkn_item_prd                             -- �g�[�N���R�[�h3
                          ,iv_token_value3 => lv_category_val                             -- �g�[�N���l3
                          ,iv_token_name4  => cv_tkn_par_item_prd                         -- �g�[�N���R�[�h4
                          ,iv_token_value4 => lv_p_item_prod_class                        -- �g�[�N���l4
                         );
            -- ���b�Z�[�W�o��
            xxcmm_004common_pkg.put_message(
              iv_message_buff => lv_errmsg
             ,ov_errbuf       => lv_errbuf
             ,ov_retcode      => lv_retcode
             ,ov_errmsg       => lv_errmsg
            );
            --
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
-- End
      END IF;
      --
      --==============================================================
      -- A-4.30 ���X�d����`�F�b�N
      -- ���i���i�敪���u1:���i�v�̏ꍇ�A�q�i�ڂ͐e�l�p��
      -- ���i���i�敪���u2:���i�v�̏ꍇ�A�e�q�Ƃ�LOOKUP�\���݃`�F�b�N���s���܂��B
      --==============================================================
      lv_step := 'A-4.30.1';
      -- ���X�d���� IS NULL��
      IF ( i_wk_item_rec.sp_supplier_code IS NULL ) THEN
        -- �e�i�ڎ�
        IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
          -- ���i���i�敪���u1:���i�v�̏ꍇ�A���X�d����͕K�{�ƂȂ�܂��B
-- Ver1.8  2009/05/19  �o�O�H�H  �㏑�����ꂽ���i���i�敪������悤�C��
--          IF ( TO_NUMBER(i_wk_item_rec.item_product_class) = cn_item_prod_item ) THEN
          IF ( TO_NUMBER( lv_p_item_prod_class ) = cn_item_prod_item ) THEN
-- End
            -- ���i���i�敪���i���K�{�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm                          -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_xxcmm_00417                          -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_input_line_no                        -- �g�[�N���R�[�h1
                          ,iv_token_value1 => i_wk_item_rec.line_no                       -- �g�[�N���l1
                          ,iv_token_name2  => cv_tkn_input_item_code                      -- �g�[�N���R�[�h2
                          ,iv_token_value2 => i_wk_item_rec.item_code                     -- �g�[�N���l2
                         );
            -- ���b�Z�[�W�o��
            xxcmm_004common_pkg.put_message(
              iv_message_buff => lv_errmsg
             ,ov_errbuf       => lv_errbuf
             ,ov_retcode      => lv_retcode
             ,ov_errmsg       => lv_errmsg
            );
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
        --
      -- ���X�d���� IS NOT NULL��
      ELSE
        lv_step := 'A-4.30.2';
        -- LOOKUP�\���݃`�F�b�N
        -- ������
        l_lookup_rec := NULL;
        l_lookup_rec.lookup_type := cv_lookup_senmonten;
        l_lookup_rec.lookup_code := i_wk_item_rec.sp_supplier_code;
        l_lookup_rec.line_no     := i_wk_item_rec.line_no;
        l_lookup_rec.item_code   := i_wk_item_rec.item_code;
        -- LOOKUP�\���݃`�F�b�N
        chk_exists_lookup(
          io_lookup_rec => l_lookup_rec
         ,ov_errbuf     => lv_errbuf
         ,ov_retcode    => lv_retcode
         ,ov_errmsg     => lv_errmsg
        );
        -- �������ʃ`�F�b�N
        IF ( lv_retcode <> cv_status_normal ) THEN
          lv_check_flag := cv_status_error;
        END IF;
        --
      END IF;
    END IF;
    --
--Ver1.11  2009/06/11 Add start
    --==============================================================
    -- �q�i�ڎ��̌p���`�F�b�N(�e�l������΂��̂܂ܐݒ肷��)
    --==============================================================
    IF ( i_wk_item_rec.item_code <> i_wk_item_rec.parent_item_code ) THEN
      --
      --==============================================================
      -- A-4.33 �o�����敪(�e�l�擾)
      --==============================================================
      lv_step := 'A-4.33';
      OPEN get_categ_cur( i_wk_item_rec.parent_item_code, cv_categ_set_baracha_div );
      --
      FETCH get_categ_cur INTO l_item_ctg_rec.bd_category_id, l_item_ctg_rec.bd_category_set_id;
      --
      CLOSE get_categ_cur;
      --
      --==============================================================
      -- A-4.34 �}�[�P�p�Q�R�[�h(�e�l�擾)
      --==============================================================
      lv_step := 'A-4.34';
      OPEN get_categ_cur( i_wk_item_rec.parent_item_code, cv_categ_set_mark_pg );
      --
      FETCH get_categ_cur INTO l_item_ctg_rec.mgc_category_id, l_item_ctg_rec.mgc_category_set_id;
      --
      CLOSE get_categ_cur;
      --
      --==============================================================
      -- A-4.35 �Q�R�[�h(�e�l�擾)
      --==============================================================
      lv_step := 'A-4.35';
      OPEN get_categ_cur( i_wk_item_rec.parent_item_code, cv_categ_set_gun_code );
      --
      FETCH get_categ_cur INTO l_item_ctg_rec.pg_category_id, l_item_ctg_rec.pg_category_set_id;
      --
      CLOSE get_categ_cur;
      --
      IF ( l_item_ctg_rec.pg_category_set_id IS NULL ) THEN
        -- �Q�R�[�h����ϐ��ɃZ�b�g
        l_item_ctg_rec.category_set_name := cv_categ_set_gun_code;
        -- �e�̐���Q�̌��ݒl�𒊏o
        SELECT    iimb.attribute2
        INTO      l_item_ctg_rec.category_val
        FROM      ic_item_mst_b        iimb
        WHERE     iimb.item_no = i_wk_item_rec.parent_item_code;
        --
        -- �J�e�S�����݃`�F�b�N
        chk_exists_category(
          io_item_ctg_rec => l_item_ctg_rec
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        -- �������ʃ`�F�b�N
        IF ( lv_retcode <> cv_status_normal ) THEN
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
    END IF;
    --
    --==============================================================
    -- �e�i�ڎ��A�܂��́A�q�i�ڎ��e�i�ڂɐݒ肳��Ă��Ȃ���ΐݒ肷��
    --==============================================================
    -- �o�����敪
    IF ( l_item_ctg_rec.bd_category_set_id IS NULL ) THEN
      l_item_ctg_rec.category_set_name := cv_categ_set_baracha_div;
      l_item_ctg_rec.category_val      := gn_baracha_div;
      --
      -- �J�e�S�����݃`�F�b�N
      chk_exists_category(
        io_item_ctg_rec => l_item_ctg_rec
       ,ov_errbuf       => lv_errbuf
       ,ov_retcode      => lv_retcode
       ,ov_errmsg       => lv_errmsg
      );
    END IF;
    --
    -- �}�[�P�p�Q�R�[�h
    IF ( l_item_ctg_rec.mgc_category_set_id IS NULL ) THEN
      l_item_ctg_rec.category_set_name := cv_categ_set_mark_pg;
      l_item_ctg_rec.category_val      := gv_mark_pg;
      --
      -- �J�e�S�����݃`�F�b�N
      chk_exists_category(
        io_item_ctg_rec => l_item_ctg_rec
       ,ov_errbuf       => lv_errbuf
       ,ov_retcode      => lv_retcode
       ,ov_errmsg       => lv_errmsg
      );
    END IF;
--Ver1.11  2009/06/11 End
-- 2009/09/07 Ver1.15 ��Q0001258 add start by Y.Kuboshima
    --
    --==============================================================
    -- A-4.38 �i�ڋ敪
    --==============================================================
    lv_step := 'A-4.38';
    l_item_ctg_rec.category_set_name := cv_categ_set_item_div;
    l_item_ctg_rec.category_val      := gv_item_div;
    --
    -- �J�e�S�����݃`�F�b�N
    chk_exists_category(
      io_item_ctg_rec => l_item_ctg_rec
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- A-4.39 ���O�敪
    --==============================================================
    lv_step := 'A-4.39';
    l_item_ctg_rec.category_set_name := cv_categ_set_inout_div;
    l_item_ctg_rec.category_val      := gv_inout_div;
    --
    -- �J�e�S�����݃`�F�b�N
    chk_exists_category(
      io_item_ctg_rec => l_item_ctg_rec
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- A-4.40 ���i�敪
    --==============================================================
    lv_step := 'A-4.40';
    l_item_ctg_rec.category_set_name := cv_categ_set_product_div;
    l_item_ctg_rec.category_val      := gv_product_div;
    --
    -- �J�e�S�����݃`�F�b�N
    chk_exists_category(
      io_item_ctg_rec => l_item_ctg_rec
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- A-4.41 �i���敪
    --==============================================================
    lv_step := 'A-4.41';
    l_item_ctg_rec.category_set_name := cv_categ_set_quality_div;
    l_item_ctg_rec.category_val      := gv_quality_div;
    --
    -- �J�e�S�����݃`�F�b�N
    chk_exists_category(
      io_item_ctg_rec => l_item_ctg_rec
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- A-4.42 �H��Q�R�[�h
    --==============================================================
    lv_step := 'A-4.42';
    l_item_ctg_rec.category_set_name := cv_categ_set_fact_pg;
    l_item_ctg_rec.category_val      := gv_fact_pg;
    --
    -- �J�e�S�����݃`�F�b�N
    chk_exists_category(
      io_item_ctg_rec => l_item_ctg_rec
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- A-4.43 �o�����p�Q�R�[�h
    --==============================================================
    lv_step := 'A-4.43';
    l_item_ctg_rec.category_set_name := cv_categ_set_acnt_pg;
    l_item_ctg_rec.category_val      := gv_acnt_pg;
    --
    -- �J�e�S�����݃`�F�b�N
    chk_exists_category(
      io_item_ctg_rec => l_item_ctg_rec
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_check_flag := cv_status_error;
    END IF;
-- 2009/09/07 Ver1.15 ��Q0001258 add end by Y.Kuboshima
    --
    --==============================================================
    -- A-4.44 �����������Z
    --==============================================================
    lv_step := 'A-4.44';
    IF ( lv_check_flag = cv_status_normal )THEN
      ov_retcode := cv_status_normal;
    ELSIF ( lv_check_flag = cv_status_error ) THEN
      ov_retcode := cv_status_error;
    END IF;
    --
    -- �J�e�S������߂��܂��B(�e�i�ڂ̏ꍇ�̂ݒl�������Ă�����)
    o_item_ctg_rec := l_item_ctg_rec;
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END validate_item;
--
  /**********************************************************************************
   * Procedure Name   : loop_main
   * Description      : �i�ڈꊇ�o�^���[�N�f�[�^�擾 (A-3)
   ***********************************************************************************/
  PROCEDURE loop_main(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'loop_main'; -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(10);                                     -- �X�e�b�v
    ln_line_cnt               NUMBER;                                           -- �s�J�E���^
    lv_check_flag             VARCHAR2(1);                                      -- �`�F�b�N�t���O
    lv_error_flg              VARCHAR2(1);                                      -- �ޔ�p���^�[���E�R�[�h
    l_line_no_tab             g_check_data_ttype;                               -- �e�[�u���^�ϐ���錾(�s�ԍ��ێ�)
    l_item_code_tab           g_check_data_ttype;                               -- �e�[�u���^�ϐ���錾(�i���R�[�h�ێ�)
    lv_check_flag_item_prod   VARCHAR2(1);                                      -- �`�F�b�N�t���O(���i���i�敪)
    ln_request_id             NUMBER;                                           -- �v��ID
    l_conc_argument_tab       xxcmm_004common_pkg.conc_argument_ttype;          -- �R���J�����g(argument)
    l_item_ctg_rec            g_item_ctg_rtype;                                 -- �J�e�S�����
    l_etc_rec                 g_etc_rtype;                                      -- ���̑����
--ito->20090213 Add
    lv_status_val             VARCHAR2(5000);                                   -- �X�e�[�^�X�l
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �i�ڈꊇ�o�^���[�N�f�[�^�擾�J�[�\��
    CURSOR get_data_cur
    IS
      SELECT     xwibr.file_id                       AS file_id                 -- �t�@�C��ID
                ,xwibr.file_seq                      AS file_seq                -- �t�@�C���V�[�P���X
                ,TRIM(xwibr.line_no)                 AS line_no                 -- �s�ԍ�
                ,TRIM(xwibr.item_code)               AS item_code               -- �i���R�[�h
                ,TRIM(xwibr.item_name)               AS item_name               -- ������
                ,TRIM(xwibr.item_short_name)         AS item_short_name         -- ����
                ,TRIM(xwibr.item_name_alt)           AS item_name_alt           -- �J�i��
                ,TRIM(xwibr.item_status)             AS item_status             -- �i�ڃX�e�[�^�X
                ,TRIM(xwibr.sales_target_flag)       AS sales_target_flag       -- ����Ώۋ敪
                ,TRIM(xwibr.parent_item_code)        AS parent_item_code        -- �e���i�R�[�h
                ,TRIM(xwibr.case_inc_num)            AS case_inc_num            -- �P�[�X����
-- Ver1.8  2009/05/18 Add  T1_0906 �P�[�X���Z������ǉ�
                ,TRIM(case_conv_inc_num)             AS case_conv_inc_num       -- �P�[�X���Z����
-- End
                ,TRIM(xwibr.item_um)                 AS item_um                 -- ��P��
                ,TRIM(xwibr.item_product_class)      AS item_product_class      -- ���i���i�敪
                ,TRIM(xwibr.rate_class)              AS rate_class              -- ���敪
                ,TRIM(xwibr.net)                     AS net                     -- NET
                ,TRIM(xwibr.weight_volume)           AS weight_volume           -- �d�ʁ^�̐�
                ,TRIM(xwibr.jan_code)                AS jan_code                -- JAN�R�[�h
                ,TRIM(xwibr.nets)                    AS nets                    -- ���e��
                ,TRIM(xwibr.nets_uom_code)           AS nets_uom_code           -- ���e�ʒP��
                ,TRIM(xwibr.inc_num)                 AS inc_num                 -- �������
                ,TRIM(xwibr.case_jan_code)           AS case_jan_code           -- �P�[�XJAN�R�[�h
                ,TRIM(xwibr.hon_product_class)       AS hon_product_class       -- �{�Џ��i�敪
                ,TRIM(xwibr.baracha_div)             AS baracha_div             -- �o�����敪
                ,TRIM(xwibr.itf_code)                AS itf_code                -- ITF�R�[�h
                ,TRIM(xwibr.product_class)           AS product_class           -- ���i����
                ,TRIM(xwibr.palette_max_cs_qty)      AS palette_max_cs_qty      -- �z��
                ,TRIM(xwibr.palette_max_step_qty)    AS palette_max_step_qty    -- �i��
                ,TRIM(xwibr.bowl_inc_num)            AS bowl_inc_num            -- �{�[������
                ,TRIM(xwibr.sale_start_date)         AS sale_start_date         -- �����J�n��
                ,TRIM(xwibr.vessel_group)            AS vessel_group            -- �e��Q
                ,TRIM(xwibr.new_item_div)            AS new_item_div            -- �V���i�敪
                ,TRIM(xwibr.acnt_group)              AS acnt_group              -- �o���Q
                ,TRIM(xwibr.acnt_vessel_group)       AS acnt_vessel_group       -- �o���e��Q
                ,TRIM(xwibr.brand_group)             AS brand_group             -- �u�����h�Q
                ,TRIM(xwibr.policy_group)            AS policy_group            -- ����Q
                ,TRIM(xwibr.list_price)              AS list_price              -- �艿
                ,TRIM(xwibr.standard_price_1)        AS standard_price_1        -- ����(�W������)
                ,TRIM(xwibr.standard_price_2)        AS standard_price_2        -- �Đ���(�W������)
                ,TRIM(xwibr.standard_price_3)        AS standard_price_3        -- ���ޔ�(�W������)
                ,TRIM(xwibr.standard_price_4)        AS standard_price_4        -- ���(�W������)
                ,TRIM(xwibr.standard_price_5)        AS standard_price_5        -- �O���Ǘ���(�W������)
                ,TRIM(xwibr.standard_price_6)        AS standard_price_6        -- �ۊǔ�(�W������)
                ,TRIM(xwibr.standard_price_7)        AS standard_price_7        -- ���̑��o��(�W������)
                ,TRIM(xwibr.business_price)          AS business_price          -- �c�ƌ���
                ,TRIM(xwibr.renewal_item_code)       AS renewal_item_code       -- ���j���[�A�������i�R�[�h
                ,TRIM(xwibr.sp_supplier_code)        AS sp_supplier_code        -- ���X�d����R�[�h
                ,xwibr.created_by                                               -- �쐬��
                ,xwibr.creation_date                                            -- �쐬��
                ,xwibr.last_updated_by                                          -- �ŏI�X�V��
                ,xwibr.last_update_date                                         -- �ŏI�X�V��
                ,xwibr.last_update_login                                        -- �ŏI�X�V���O�C��ID
                ,xwibr.request_id                                               -- �v��ID
                ,xwibr.program_application_id                                   -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
                ,xwibr.program_id                                               -- �R���J�����g�E�v���O����ID
                ,xwibr.program_update_date                                      -- �v���O�����ɂ��X�V��
      FROM       xxcmm_wk_item_batch_regist  xwibr                              -- �i�ڈꊇ�o�^���[�N
      WHERE      xwibr.request_id = cn_request_id                               -- �v��ID
      ORDER BY   file_seq                                                       -- �t�@�C���V�[�P���X
      ;
    --
    -- ���i���i�敪�擾�J�[�\��
    CURSOR get_item_prod_cur
    IS
      SELECT    mcv.attribute1      AS dualum_ind                               -- ��d�Ǘ�
               ,mcv.attribute2      AS lot_ctl                                  -- ���b�g
      FROM      mtl_categories_vl      mcv,                                     -- �J�e�S��
                mtl_category_sets_vl   mcsv                                     -- �J�e�S���Z�b�g
      WHERE     mcv.structure_id       = mcsv.structure_id
      AND       mcsv.category_set_name = cv_item_product_class
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
    --
--##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  �Œ蕔 END   ############################
    --
    -- �`�F�b�N�t���O�̏�����
    lv_check_flag            := cv_status_normal;
    lv_check_flag_item_prod  := cv_status_normal;
    --
    --==============================================================
    -- ���i���i�敪DFF�`�F�b�N
    -- OPM�i�ڂ̓�d�Ǘ��A���b�g�͏��i���i�敪��DFF���擾���邪���ݒ�̏ꍇ�̓G���[�Ƃ��܂��B(NOT NULL���ڂȂ̂�)
    --==============================================================
    lv_step := 'A-3.1';
    <<item_product_loop>>
    FOR get_item_prod_rec IN get_item_prod_cur LOOP
      -- ��d�Ǘ��A���b�gNULL�`�F�b�N
      IF (( get_item_prod_rec.dualum_ind IS NULL ) OR ( get_item_prod_rec.lot_ctl IS NULL )) THEN
        lv_check_flag_item_prod := cv_status_error;
      END IF;
    END LOOP item_product_loop;
    --
    -- �������ʃ`�F�b�N
    IF ( lv_check_flag_item_prod = cv_status_error ) THEN
      -- ���i���i�敪DFF���ݒ�G���[
      lv_errmsg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_appl_name_xxcmm                  -- �A�v���P�[�V�����Z�k��
                      ,iv_name          =>  cv_msg_xxcmm_00420                  -- ���b�Z�[�W�R�[�h
                     );
      -- ���b�Z�[�W�o��
      xxcmm_004common_pkg.put_message(
        iv_message_buff  =>  lv_errmsg
       ,ov_errbuf        =>  lv_errbuf
       ,ov_retcode       =>  lv_retcode
       ,ov_errmsg        =>  lv_errmsg
      );
    END IF;
    --
    ln_line_cnt := 0;
    <<main_loop>>
    FOR get_data_rec IN get_data_cur LOOP
      -- ������
      lv_error_flg := cv_status_normal;
      --
      -- �s�J�E���^�A�b�v
      ln_line_cnt := ln_line_cnt + 1;
      --==============================================================
      -- A-4  �f�[�^�Ó����`�F�b�N
      --==============================================================
      lv_step := 'A-4';
      validate_item(
        i_wk_item_rec  => get_data_rec             -- �i�ڈꊇ�o�^���[�N���
       ,o_item_ctg_rec => l_item_ctg_rec           -- �J�e�S�����
       ,o_etc_rec      => l_etc_rec                -- ���̑����
       ,ov_errbuf      => lv_errbuf                -- �G���[�E���b�Z�[�W
       ,ov_retcode     => lv_retcode               -- ���^�[���E�R�[�h
       ,ov_errmsg      => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- �������ʃ`�F�b�N
      IF ( lv_retcode = cv_status_normal ) THEN
        -- OPM�i�ڂ̓�d�Ǘ��A���b�g��NULL�̏ꍇ�A�o�^�����͍s���܂���B
        IF ( lv_check_flag_item_prod = cv_status_normal ) THEN
          --==============================================================
          -- A-5  �f�[�^�o�^
          --==============================================================
          lv_step := 'A-5';
          ins_data(
            i_wk_item_rec  => get_data_rec             -- �i�ڈꊇ�o�^���[�N���
           ,i_item_ctg_rec => l_item_ctg_rec           -- �J�e�S�����
           ,i_etc_rec      => l_etc_rec                -- ���̑����
           ,ov_errbuf      => lv_errbuf                -- �G���[�E���b�Z�[�W
           ,ov_retcode     => lv_retcode               -- ���^�[���E�R�[�h
           ,ov_errmsg      => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          -- �������ʃ`�F�b�N
          IF ( lv_retcode = cv_status_normal ) THEN
            -- �\�ߍs�ԍ��A�i���R�[�h��ϐ��ɑޔ����Ă����܂��B
            -- A-5.2�Ŏg�p���܂��B
            l_line_no_tab(ln_line_cnt)   := get_data_rec.line_no;
            l_item_code_tab(ln_line_cnt) := get_data_rec.item_code;
          ELSIF ( lv_retcode = cv_status_error ) THEN
            -- �G���[�X�e�[�^�X�ޔ�
            lv_error_flg := lv_retcode;
          END IF;
        END IF;
        --
      ELSE
        -- �f�[�^�Ó����`�F�b�N�G���[�̏ꍇ
        -- �G���[�X�e�[�^�X�ޔ�
        lv_error_flg := lv_retcode;
      END IF;
      --
      --==============================================================
      -- �����������Z
      --==============================================================
      IF ( lv_error_flg = cv_status_normal ) THEN
        IF ( lv_check_flag_item_prod = cv_status_normal ) THEN
          gn_normal_cnt := gn_normal_cnt + 1;
        ELSE
          gn_error_cnt  := gn_error_cnt + 1;
          lv_check_flag := cv_status_error;
        END IF;
      ELSE
        gn_error_cnt  := gn_error_cnt + 1;
        lv_check_flag := cv_status_error;
      END IF;
    END LOOP main_loop;
    --
    -- OPM�i�ڂ̓�d�Ǘ��A���b�g��NULL�̏ꍇ�A�G���[���Z�b�g
    IF ( lv_check_flag_item_prod = cv_status_error ) THEN
      lv_retcode := cv_status_error;
    ELSE
      -- �Ó����A�o�^�G���[�̏ꍇ�A�G���[���Z�b�g
      IF ( lv_check_flag = cv_status_error ) THEN
        lv_retcode := cv_status_error;
      END IF;
    END IF;
    --
    -- �������ʃ`�F�b�N
    IF ( lv_retcode = cv_status_normal ) THEN
      --==============================================================
      -- A-5.2 Disc�i�ړo�^����
      -- �S�Ă̓o�^����������������i�ڈꊇ�o�^���[�N�̃��R�[�h���A�R���J�����g���N�����܂��B
      --==============================================================
      lv_step := 'A-5.2';
      COMMIT;
      --
      -- Disc�i�ړo�^LOOP
      <<loop_conc>>
      FOR ln_conc_cnt IN 1..l_item_code_tab.COUNT LOOP
        -- ���uOPM�i�ڃg���K�[�N���R���J�����g�v���s
        -- argument�ݒ�
        l_conc_argument_tab(1).argument := l_item_code_tab(ln_conc_cnt);
        <<loop_arg>>
        FOR ln_cnt IN 2..100 LOOP
          l_conc_argument_tab(ln_cnt).argument := CHR(0);
        END LOOP loop_arg;
        --
        xxcmm_004common_pkg.proc_conc_request(
          iv_appl_short_name => cv_appl_name_xxcmn
         ,iv_program         => cv_prog_opmitem_trigger
         ,iv_description     => NULL
         ,iv_start_time      => NULL
         ,ib_sub_request     => FALSE
         ,i_argument_tab     => l_conc_argument_tab
         ,iv_wait_flag       => cv_yes
         ,on_request_id      => ln_request_id
         ,ov_errbuf          => lv_errbuf
         ,ov_retcode         => lv_retcode
         ,ov_errmsg          => lv_errmsg
        );
        --
--ito->20090213 Add START
        IF ( lv_retcode = cv_status_normal ) THEN
          lv_status_val := cv_status_val_normal;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          lv_status_val := SUBSTRB(cv_status_val_warn || cv_msg_part || lv_errmsg, 1, 5000);
        ELSE
          lv_status_val := SUBSTRB(cv_status_val_error || cv_msg_part || lv_errmsg, 1, 5000);
        END IF;
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          ov_retcode := cv_status_error;
          gn_normal_cnt := gn_normal_cnt - 1;
          gn_error_cnt  := gn_error_cnt + 1;
        END IF;
--ito->20090213 Add END
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00408                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_req_id                         -- �g�[�N���R�[�h1
                      ,iv_token_value1 => ln_request_id                         -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h2
                      ,iv_token_value2 => l_line_no_tab(ln_conc_cnt)            -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_item_code                -- �g�[�N���R�[�h3
                      ,iv_token_value3 => l_item_code_tab(ln_conc_cnt)          -- �g�[�N���l3
                      ,iv_token_name4  => cv_tkn_msg                            -- �g�[�N���R�[�h4
                      ,iv_token_value4 => lv_status_val                         -- �g�[�N���l4
                     );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
      END LOOP loop_conc;
    ELSE
      ov_retcode := cv_status_error;
    END IF;
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END loop_main;
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_if_data';        -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(10);                           -- �X�e�b�v
    --
    ln_line_cnt               NUMBER;                                 -- �s�J�E���^
    ln_item_num               NUMBER;                                 -- ���ڐ�
    ln_item_cnt               NUMBER;                                 -- ���ڐ��J�E���^
    lv_file_name              VARCHAR2(100);                          -- �t�@�C�����i�[�p
    ln_ins_item_cnt           NUMBER;                                 -- �o�^�����J�E���^
--
    l_wk_item_tab             g_check_data_ttype;                     --  �e�[�u���^�ϐ���錾(���ڕ���)
    l_if_data_tab             xxccp_common_pkg2.g_file_data_tbl;      --  �e�[�u���^�ϐ���錾
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
    get_if_data_expt          EXCEPTION;                              -- �f�[�^���ڐ��G���[��O
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ϐ�������
    ln_ins_item_cnt := 0;
    --
    --==============================================================
    -- A-2.1 �Ώۃf�[�^�̕���(���R�[�h����)
    --==============================================================
    lv_step := 'A-2.1';
    xxccp_common_pkg2.blob_to_varchar2(                               -- BLOB�f�[�^�ϊ����ʊ֐�
      in_file_id   => gn_file_id                                      -- �t�@�C���h�c
     ,ov_file_data => l_if_data_tab                                   -- �ϊ���VARCHAR2�f�[�^
     ,ov_errbuf    => lv_errbuf                                       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode                                      -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    --
    -- ���[�N�e�[�u���o�^LOOP
    <<ins_wk_loop>>
    FOR ln_line_cnt IN 1..l_if_data_tab.COUNT LOOP
      --==============================================================
      -- A-2.2 ���ڐ��̃`�F�b�N
      --==============================================================
      lv_step := 'A-2.2';
      -- �f�[�^���ڐ����i�[
      ln_item_num := ( LENGTHB(l_if_data_tab( ln_line_cnt))
                   - ( LENGTHB(REPLACE(l_if_data_tab(ln_line_cnt), cv_msg_comma, '')))
                   + 1);
      -- ���ڐ�����v���Ȃ��ꍇ
      IF ( gn_item_num <> ln_item_num ) THEN
        RAISE get_if_data_expt;
      END IF;
      --
      --==============================================================
      -- A-2.3.1 �Ώۃf�[�^�̕���(���ڕ���)
      --==============================================================
      lv_step := 'A-2.3.1';
      <<get_column_loop>>
      FOR ln_item_cnt IN 1..gn_item_num LOOP
        -- �ϐ��ɍ��ڂ̒l���i�[
        l_wk_item_tab(ln_item_cnt) := xxccp_common_pkg.char_delim_partition(  -- �f���~�^�����ϊ����ʊ֐�
                                        iv_char     => l_if_data_tab(ln_line_cnt)
                                       ,iv_delim    => cv_msg_comma
                                       ,in_part_num => ln_item_cnt
                                      );
      END LOOP get_column_loop;
      --
      --==============================================================
      -- A-2.3.2 �i�ڈꊇ�o�^���[�N�֓o�^
      --==============================================================
      lv_step := 'A-2.3.2';
      BEGIN
        ln_ins_item_cnt := ln_ins_item_cnt + 1;
        --
        INSERT INTO xxcmm_wk_item_batch_regist(
          file_id                       -- �t�@�C��ID
         ,file_seq                      -- �t�@�C���V�[�P���X
         ,line_no                       -- �s�ԍ�
         ,item_code                     -- �i���R�[�h
         ,item_name                     -- ������
         ,item_short_name               -- ����
         ,item_name_alt                 -- �J�i��
         ,item_status                   -- �i�ڃX�e�[�^�X
         ,sales_target_flag             -- ����Ώۋ敪
         ,parent_item_code              -- �e���i�R�[�h
         ,case_inc_num                  -- �P�[�X����
-- Ver1.8  2009/05/18 Add  T1_0906 �P�[�X���Z������ǉ�
         ,case_conv_inc_num             -- �P�[�X���Z����
-- End
         ,item_um                       -- ��P��
         ,item_product_class            -- ���i���i�敪
         ,rate_class                    -- ���敪
         ,net                           -- NET
         ,weight_volume                 -- �d�ʁ^�̐�
         ,jan_code                      -- JAN�R�[�h
         ,nets                          -- ���e��
         ,nets_uom_code                 -- ���e�ʒP��
         ,inc_num                       -- �������
         ,case_jan_code                 -- �P�[�XJAN�R�[�h
         ,hon_product_class             -- �{�Џ��i�敪
         ,baracha_div                   -- �o�����敪
         ,itf_code                      -- ITF�R�[�h
         ,product_class                 -- ���i����
         ,palette_max_cs_qty            -- �z��
         ,palette_max_step_qty          -- �i��
         ,bowl_inc_num                  -- �{�[������
         ,sale_start_date               -- �����J�n��
         ,vessel_group                  -- �e��Q
         ,new_item_div                  -- �V���i�敪
         ,acnt_group                    -- �o���Q
         ,acnt_vessel_group             -- �o���e��Q
         ,brand_group                   -- �u�����h�Q
         ,policy_group                  -- ����Q
         ,list_price                    -- �艿
         ,standard_price_1              -- ����(�W������)
         ,standard_price_2              -- �Đ���(�W������)
         ,standard_price_3              -- ���ޔ�(�W������)
         ,standard_price_4              -- ���(�W������)
         ,standard_price_5              -- �O���Ǘ���(�W������)
         ,standard_price_6              -- �ۊǔ�(�W������)
         ,standard_price_7              -- ���̑��o��(�W������)
         ,business_price                -- �c�ƌ���
         ,renewal_item_code             -- ���j���[�A�������i�R�[�h
         ,sp_supplier_code              -- ���X�d����R�[�h
         ,created_by                    -- �쐬��
         ,creation_date                 -- �쐬��
         ,last_updated_by               -- �ŏI�X�V��
         ,last_update_date              -- �ŏI�X�V��
         ,last_update_login             -- �ŏI�X�V���O�C��ID
         ,request_id                    -- �v��ID
         ,program_application_id        -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
         ,program_id                    -- �R���J�����g�E�v���O����ID
         ,program_update_date           -- �v���O�����ɂ��X�V��
         ) VALUES (
          gn_file_id                    -- �t�@�C��ID
         ,ln_ins_item_cnt               -- �t�@�C���V�[�P���X
         ,l_wk_item_tab(1)              -- �s�ԍ�
         ,l_wk_item_tab(2)              -- �i���R�[�h
         ,l_wk_item_tab(3)              -- ������
         ,l_wk_item_tab(4)              -- ����
         ,l_wk_item_tab(5)              -- �J�i��
         ,l_wk_item_tab(6)              -- �i�ڃX�e�[�^�X
         ,l_wk_item_tab(7)              -- ����Ώۋ敪
         ,l_wk_item_tab(8)              -- �e���i�R�[�h
         ,l_wk_item_tab(9)              -- �P�[�X����
-- Ver1.8  2009/05/18 Add  T1_0906 �P�[�X���Z������ǉ�
         ,l_wk_item_tab(10)             -- �P�[�X���Z����
-- End
         ,l_wk_item_tab(11)             -- ��P��
         ,l_wk_item_tab(12)             -- ���i���i�敪
         ,l_wk_item_tab(13)             -- ���敪
         ,l_wk_item_tab(14)             -- NET
         ,l_wk_item_tab(15)             -- �d�ʁ^�̐�
         ,l_wk_item_tab(16)             -- JAN�R�[�h
         ,l_wk_item_tab(17)             -- ���e��
         ,l_wk_item_tab(18)             -- ���e�ʒP��
         ,l_wk_item_tab(19)             -- �������
         ,l_wk_item_tab(20)             -- �P�[�XJAN�R�[�h
         ,l_wk_item_tab(21)             -- �{�Џ��i�敪
         ,l_wk_item_tab(22)             -- �o�����敪
         ,l_wk_item_tab(23)             -- ITF�R�[�h
         ,l_wk_item_tab(24)             -- ���i����
         ,l_wk_item_tab(25)             -- �z��
         ,l_wk_item_tab(26)             -- �i��
         ,l_wk_item_tab(27)             -- �{�[������
         ,l_wk_item_tab(28)             -- �����J�n��
         ,l_wk_item_tab(29)             -- �e��Q
         ,l_wk_item_tab(30)             -- �V���i�敪
         ,l_wk_item_tab(31)             -- �o���Q
         ,l_wk_item_tab(32)             -- �o���e��Q
         ,l_wk_item_tab(33)             -- �u�����h�Q
         ,l_wk_item_tab(34)             -- ����Q
         ,l_wk_item_tab(35)             -- �艿
         ,l_wk_item_tab(36)             -- ����(�W������)
         ,l_wk_item_tab(37)             -- �Đ���(�W������)
         ,l_wk_item_tab(38)             -- ���ޔ�(�W������)
         ,l_wk_item_tab(39)             -- ���(�W������)
         ,l_wk_item_tab(40)             -- �O���Ǘ���(�W������)
         ,l_wk_item_tab(41)             -- �ۊǔ�(�W������)
         ,l_wk_item_tab(42)             -- ���̑��o��(�W������)
         ,l_wk_item_tab(43)             -- �c�ƌ���
         ,l_wk_item_tab(44)             -- ���j���[�A�������i�R�[�h
         ,l_wk_item_tab(45)             -- ���X�d����R�[�h
         ,cn_created_by                 -- �쐬��
         ,cd_creation_date              -- �쐬��
         ,cn_last_updated_by            -- �ŏI�X�V��
         ,cd_last_update_date           -- �ŏI�X�V��
         ,cn_last_update_login          -- �ŏI�X�V���O�C��ID
         ,cn_request_id                 -- �v��ID
         ,cn_program_application_id     -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
         ,cn_program_id                 -- �R���J�����g�E�v���O����ID
         ,cd_program_update_date        -- �v���O�����ɂ��X�V��
        );
      EXCEPTION
        -- *** �f�[�^�o�^��O�n���h�� ***
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcmm       -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_xxcmm_00407       -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_table             -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_table_xwibr           -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_input_line_no     -- �g�[�N���R�[�h2
                         ,iv_token_value2 => l_wk_item_tab(1)         -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_input_item_code   -- �g�[�N���R�[�h3
                         ,iv_token_value3 => l_wk_item_tab(2)         -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_errmsg            -- �g�[�N���R�[�h4
                         ,iv_token_value4 => SQLERRM                  -- �g�[�N���l4
                        );
          -- ���b�Z�[�W�o��
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          --
          -- �G���[�����J�E���g�A�b�v
          -- �����ŃG���[�ƂȂ������̂͑Ó����`�F�b�N�͍s���܂���B
          gn_error_cnt := gn_error_cnt + 1;
      END;
    END LOOP ins_wk_loop;
    --
    -- �����Ώی������i�[
    gn_target_cnt := l_if_data_tab.COUNT;
    --
  EXCEPTION
    -- *** �f�[�^���ڐ��G���[��O�n���h�� ***
    WHEN get_if_data_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00028            -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_item_batch_regist          -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_count                  -- �g�[�N���R�[�h2
                    ,iv_token_value2 => ln_item_num                   -- �g�[�N���l2
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    iv_file_id    IN  VARCHAR2          -- 1.�t�@�C��ID
   ,iv_format     IN  VARCHAR2          -- 2.�t�H�[�}�b�g
   ,ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init';              -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(10);                           -- �X�e�b�v
    lv_tkn_value              VARCHAR2(100);                          -- �g�[�N���l
    lv_sqlerrm                VARCHAR2(5000);                         -- SQLERRM��ޔ�
    --
    lv_upload_obj             VARCHAR2(100);                          -- �t�@�C���A�b�v���[�h����
    lv_up_name                VARCHAR2(1000);                         -- �A�b�v���[�h���̏o�͗p
    lv_file_id                VARCHAR2(1000);                         -- �t�@�C��ID�o�͗p
    lv_file_format            VARCHAR2(1000);                         -- �t�H�[�}�b�g�o�͗p
    lv_file_name              VARCHAR2(1000);                         -- �t�@�C�����o�͗p
-- Ver1.3 Mod 20090216 START
    -- �t�@�C���A�b�v���[�hIF�e�[�u������
    lv_csv_file_name           xxccp_mrp_file_ul_interface.file_name%TYPE;                          -- �t�@�C�����i�[�p
    ln_created_by              xxccp_mrp_file_ul_interface.created_by%TYPE;                         -- �쐬�Ҋi�[�p
    ld_creation_date           xxccp_mrp_file_ul_interface.creation_date%TYPE;                      -- �쐬���i�[�p
--    lv_created_by             VARCHAR2(100);                          -- �쐬�Ҋi�[�p
--    lv_creation_date          VARCHAR2(100);                          -- �쐬���i�[�p
-- Ver1.3 Mod 20090216 END
    ln_cnt                    NUMBER;                                 -- �J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �f�[�^���ڒ�`�擾�p�J�[�\��
    CURSOR     get_def_info_cur
    IS
      SELECT   flv.meaning                         AS item_name                 -- ���e
              ,DECODE(flv.attribute1, cv_varchar, cv_varchar_cd
                                    , cv_number,  cv_number_cd
                                    , cv_date_cd)  AS item_attribute            -- ���ڑ���
              ,DECODE(flv.attribute2, cv_not_null, cv_null_ng
                                    , cv_null_ok)  AS item_essential            -- �K�{�t���O
              ,TO_NUMBER(flv.attribute3)           AS item_length               -- ���ڂ̒���(��������)
              ,TO_NUMBER(flv.attribute4)           AS decim                     -- ���ڂ̒���(�����_�ȉ�)
      FROM     fnd_lookup_values_vl  flv                                        -- LOOKUP�\
      WHERE    flv.lookup_type        = cv_lookup_item_def                      -- �i�ڈꊇ�o�^�f�[�^���ڒ�`
      AND      flv.enabled_flag       = cv_yes                                  -- �g�p�\�t���O
      AND      NVL(flv.start_date_active, gd_process_date) <= gd_process_date   -- �K�p�J�n��
      AND      NVL(flv.end_date_active, gd_process_date)   >= gd_process_date   -- �K�p�I����
      ORDER BY flv.lookup_code;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
    get_param_expt            EXCEPTION;                              -- �p�����[�^NULL�G���[
    get_profile_expt          EXCEPTION;                              -- �v���t�@�C���擾��O
    select_expt               EXCEPTION;                              -- �f�[�^���o�G���[
-- Ver.1.5 20090224 Add START
    process_date_expt         EXCEPTION;                              -- �Ɩ����t�擾���s�G���[
-- Ver.1.5 20090224 Add END
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- A-1.1 ���̓p�����[�^�iFILE_ID�A�t�H�[�}�b�g�j�́uNULL�v�`�F�b�N
    --==============================================================
    lv_step := 'A-1.1';
    IF ( iv_file_id IS NULL ) THEN
      lv_tkn_value := cv_file_id;
      RAISE get_param_expt;
    END IF;
    IF ( iv_format IS NULL ) THEN
      lv_tkn_value := cv_format;
      RAISE get_param_expt;
    END IF;
    --
    -- IN�p�����[�^���i�[
    gn_file_id := TO_NUMBER(iv_file_id);
    gv_format  := iv_format;
    --
    --==============================================================
    -- A-1.2 �Ɩ����t�̎擾
    --==============================================================
    lv_step := 'A-1.2';
    gd_process_date := xxccp_common_pkg2.get_process_date;
-- Ver.1.5 20090224 Add START
    -- NULL�`�F�b�N
    IF ( gd_process_date IS NULL ) THEN
      lv_tkn_value := cv_process_date;
      RAISE process_date_expt;
    END IF;
-- Ver.1.5 20090224 Add END
    --
    --==============================================================
    -- A-1.3 �v���t�@�C���擾
    --==============================================================
    lv_step := 'A-1.3';
    -- �i�ڃ}�X�^�i���n�j�A�g�pCSV�t�@�C�����̎擾
    gn_item_num := TO_NUMBER(FND_PROFILE.VALUE(cv_prof_item_num));
    -- �擾�G���[��
    IF ( gn_item_num IS NULL ) THEN
      lv_tkn_value := cv_lookup_item_defname;
      RAISE get_profile_expt;
    END IF;
    --
--Ver1.10  2009/06/04 Add start
    -- XXCMM:�i�ړo�^���_���b�g�f�t�H���g�l
    gn_lot_ctl := TO_NUMBER(FND_PROFILE.VALUE(cv_prof_lot_ctl));
    -- �擾�G���[��
    IF ( gn_lot_ctl IS NULL ) THEN
      lv_tkn_value := cv_lot_ctl_defname;
      RAISE get_profile_expt;
    END IF;
--Ver1.10  2009/06/04 End
    --
--Ver1.11  2009/06/11 Add start
    -- XXCMM:�o�����敪�����l
    gn_baracha_div := TO_NUMBER(FND_PROFILE.VALUE(cv_prof_baracha_div));
    -- �擾�G���[��
    IF ( gn_baracha_div IS NULL ) THEN
      lv_tkn_value := cv_baracha_div_def;
      RAISE get_profile_expt;
    END IF;
    --
    -- XXCMM:�}�[�P�p�Q�R�[�h�����l
    gv_mark_pg := FND_PROFILE.VALUE(cv_prof_mark_pg);
    -- �擾�G���[��
    IF ( gv_mark_pg IS NULL ) THEN
      lv_tkn_value := cv_mark_pg_def;
      RAISE get_profile_expt;
    END IF;
--Ver1.11  2009/06/11 End
    --
-- Ver1.13 2009/07/24 Add Start
    -- XXCMM:�K�p�J�n�������l
    gd_opm_apply_date := TO_DATE(FND_PROFILE.VALUE(cv_prof_apply_date),cv_date_fmt_std);
    -- �擾�G���[��
    IF ( gd_opm_apply_date IS NULL ) THEN
      lv_tkn_value := cv_apply_date_def;
      RAISE get_profile_expt;
    END IF;
-- Ver1.13 End
-- 2009/09/07 Ver1.15 ��Q0001258 add start by Y.Kuboshima
    -- XXCMM:�i�ڋ敪�����l
    gv_item_div := FND_PROFILE.VALUE(cv_prof_item_div);
    -- �擾�G���[��
    IF ( gv_item_div IS NULL ) THEN
      lv_tkn_value := cv_item_div_def;
      RAISE get_profile_expt;
    END IF;
    --
    -- XXCMM:���O�敪�����l
    gv_inout_div := FND_PROFILE.VALUE(cv_prof_inout_div);
    -- �擾�G���[��
    IF ( gv_inout_div IS NULL ) THEN
      lv_tkn_value := cv_inout_div_def;
      RAISE get_profile_expt;
    END IF;
    --
    -- XXCMM:���i�敪�����l
    gv_product_div := FND_PROFILE.VALUE(cv_prof_product_div);
    -- �擾�G���[��
    IF ( gv_product_div IS NULL ) THEN
      lv_tkn_value := cv_product_div_def;
      RAISE get_profile_expt;
    END IF;
    --
    -- XXCMM:�i���敪�����l
    gv_quality_div := FND_PROFILE.VALUE(cv_prof_quality_div);
    -- �擾�G���[��
    IF ( gv_quality_div IS NULL ) THEN
      lv_tkn_value := cv_quality_div_def;
      RAISE get_profile_expt;
    END IF;
    --
    -- XXCMM:�H��Q�R�[�h�����l
    gv_fact_pg := FND_PROFILE.VALUE(cv_prof_fact_pg);
    -- �擾�G���[��
    IF ( gv_fact_pg IS NULL ) THEN
      lv_tkn_value := cv_fact_pg_def;
      RAISE get_profile_expt;
    END IF;
    --
    -- XXCMM:�o�����p�Q�R�[�h�����l
    gv_acnt_pg := FND_PROFILE.VALUE(cv_prof_acnt_pg);
    -- �擾�G���[��
    IF ( gv_acnt_pg IS NULL ) THEN
      lv_tkn_value := cv_acnt_pg_def;
      RAISE get_profile_expt;
    END IF;
-- 2009/09/07 Ver1.15 ��Q0001258 add end by Y.Kuboshima
    --
    --==============================================================
    -- A-1.4 �t�@�C���A�b�v���[�h���̎擾
    --==============================================================
    lv_step := 'A-1.4';
    BEGIN
      SELECT   flv.meaning
      INTO     lv_upload_obj
      FROM     fnd_lookup_values_vl flv
      WHERE    flv.lookup_type  = cv_lookup_type_upload_obj                     -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
      AND      flv.lookup_code  = gv_format                                     -- �t�H�[�}�b�g
      AND      flv.enabled_flag = cv_yes                                        -- �g�p�\�t���O
      AND      NVL(flv.start_date_active, gd_process_date) <= gd_process_date   -- �K�p�J�n��
      AND      NVL(flv.end_date_active,   gd_process_date) >= gd_process_date   -- �K�p�I����
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_sqlerrm := SQLERRM;
        RAISE select_expt;
    END;
    --
    --==============================================================
    -- A-1.5 �Ώۃf�[�^���b�N�̎擾
    --==============================================================
    lv_step := 'A-1.5';
-- Ver1.3 Mod 20090216 START
    SELECT   fui.file_name                                            -- �t�@�C����
            ,fui.created_by                                           -- �쐬��
            ,fui.creation_date                                        -- �쐬��
    INTO     lv_csv_file_name
            ,ln_created_by
            ,ld_creation_date
    FROM     xxccp_mrp_file_ul_interface  fui                         -- �t�@�C���A�b�v���[�hIF�e�[�u��
    WHERE    fui.file_id = gn_file_id                                 -- �t�@�C��ID
    FOR UPDATE NOWAIT
    ;
--    SELECT   fui.file_name         file_name                          -- �t�@�C����
--            ,fui.created_by        created_by                         -- �쐬��
--            ,fui.creation_date     creation_date                      -- �쐬��
--    INTO     lv_file_name
--            ,lv_created_by
--            ,lv_creation_date
--    FROM     xxccp_mrp_file_ul_interface  fui                         -- �t�@�C���A�b�v���[�hIF�e�[�u��
--    WHERE    fui.file_id = gn_file_id                                 -- �t�@�C��ID
--    FOR UPDATE NOWAIT;
-- Ver1.3 Mod 20090216 END
    --
    --==============================================================
    -- A-1.6 �i�ڈꊇ�o�^���[�N��`���̎擾
    --==============================================================
    lv_step := 'A-1.6';
    -- �ϐ��̏�����
    ln_cnt := 0;
    -- �e�[�u����`�擾LOOP
    <<def_info_loop>>
    FOR get_def_info_rec IN get_def_info_cur LOOP
      ln_cnt := ln_cnt + 1;
      g_item_def_tab(ln_cnt).item_name      := get_def_info_rec.item_name;                -- ���ږ�
      g_item_def_tab(ln_cnt).item_attribute := get_def_info_rec.item_attribute;           -- ���ڑ���
      g_item_def_tab(ln_cnt).item_essential := get_def_info_rec.item_essential;           -- �K�{�t���O
      g_item_def_tab(ln_cnt).item_length    := get_def_info_rec.item_length;              -- ���ڂ̒���(��������)
      g_item_def_tab(ln_cnt).decim    := get_def_info_rec.decim;                          -- ���ڂ̒���(�����_�ȉ�)
    END LOOP def_info_loop;
    --
    --==============================================================
    -- A-1.7 IN�p�����[�^�̏o��
    --==============================================================
    lv_step := 'A-1.7';
    lv_up_name     := xxccp_common_pkg.get_msg(                                                     -- �A�b�v���[�h���̂̏o��
                        iv_application  => cv_appl_name_xxcmm                                       -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00021                                       -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_up_name                                           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_upload_obj                                            -- �g�[�N���l1
                      );
-- Ver1.3 Add 20090216 START
    lv_file_name   := xxccp_common_pkg.get_msg(                                                     -- �t�@�C��ID�̏o��
                        iv_application  => cv_appl_name_xxcmm                                       -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00022                                       -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_file_name                                         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_csv_file_name                                         -- �g�[�N���l1
                      );
-- Ver1.3 Add 20090216 END
    lv_file_id     := xxccp_common_pkg.get_msg(                                                     -- �t�@�C��ID�̏o��
                        iv_application  => cv_appl_name_xxcmm                                       -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00023                                       -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_file_id                                           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(gn_file_id)                                      -- �g�[�N���l1
                      );
    lv_file_format := xxccp_common_pkg.get_msg(                                                     -- �t�H�[�}�b�g�̏o��
                       iv_application  => cv_appl_name_xxcmm                                        -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00024                                        -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_file_format                                        -- �g�[�N���R�[�h1
                      ,iv_token_value1 => gv_format                                                 -- �g�[�N���l1
                      );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT                                                     -- �o�͂ɕ\��
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
                                );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG                                                        -- ���O�ɕ\��
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
                                );
--
  EXCEPTION
-- Ver.1.5 20090224 Add START
    --*** �Ɩ����t�擾���s�G���[ ***
    WHEN process_date_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00435            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_value                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                  -- �g�[�N���l1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
-- Ver.1.5 20090224 Add END
    --
    --*** �p�����[�^NULL�G���[ ***
    WHEN get_param_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00401            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_value                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                  -- �g�[�N���l1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    --
    --*** �f�[�^���o�G���[(�A�b�v���[�h�t�@�C������) ***
    WHEN select_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00439            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_table_flv                  -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_errmsg                 -- �g�[�N���R�[�h2
                    ,iv_token_value2 => lv_sqlerrm                    -- �g�[�N���l2
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    --
    --*** �v���t�@�C���擾�G���[ ***
    WHEN get_profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00002            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_ng_profile             -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                  -- �g�[�N���l1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    --
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_check_lock_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00402            -- ���b�Z�[�W�R�[�h
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id    IN  VARCHAR2          -- 1.�t�@�C��ID
   ,iv_format     IN  VARCHAR2          -- 2.�t�H�[�}�b�g
   ,ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(10);                           -- �X�e�b�v
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
    sub_proc_expt             EXCEPTION;                              -- �T�u�v���O�����G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    --==============================================================
    -- A-1.  ��������
    --==============================================================
    lv_step := 'A-1';
    proc_init(
      iv_file_id => iv_file_id          -- �t�@�C��ID
     ,iv_format  => iv_format           -- �t�H�[�}�b�g
     ,ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
--
    --==============================================================
    -- A-2.  �t�@�C���A�b�v���[�hIF�f�[�^�擾
    --==============================================================
    lv_step := 'A-2';
    get_if_data(                        -- get_if_data���R�[��
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
    --
    --==============================================================
    -- A-3  �i�ڈꊇ�o�^���[�N�f�[�^�擾
    --  A-4  �f�[�^�Ó����`�F�b�N
    --  A-5  �f�[�^�o�^
    --==============================================================
    lv_step := 'A-3';
    loop_main(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
    --==============================================================
    -- A-6  �I������
    --==============================================================
    lv_step := 'A-6';
    proc_comp(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
    --
    -- �G���[������΃��^�[���E�R�[�h���G���[�ŕԂ��܂��B
    IF ( gn_error_cnt > 0 ) THEN
      ov_retcode := cv_status_error;
    END IF;
    --
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
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
    errbuf        OUT    VARCHAR2       --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode       OUT    VARCHAR2       --   �G���[�R�[�h     #�Œ�#
   ,iv_file_id    IN     VARCHAR2       --   �t�@�C��ID
   ,iv_format     IN     VARCHAR2       --   �t�H�[�}�b�g
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';             -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';  -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';             -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';  -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
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
      iv_which   => cv_log
     ,ov_retcode => lv_retcode
     ,ov_errbuf  => lv_errbuf
     ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    -- ���b�Z�[�W(OUTPUT)�o��
    xxccp_common_pkg.put_log_header(
      iv_which   => cv_output
     ,ov_retcode => lv_retcode
     ,ov_errbuf  => lv_errbuf
     ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_file_id => iv_file_id          -- �t�@�C��ID
     ,iv_format  => iv_format           -- �t�H�[�}�b�g
     ,ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --
    --��s�}��
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => ''
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => ''
    );
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_target_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
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
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
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
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
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
END XXCMM004A05C;
/
