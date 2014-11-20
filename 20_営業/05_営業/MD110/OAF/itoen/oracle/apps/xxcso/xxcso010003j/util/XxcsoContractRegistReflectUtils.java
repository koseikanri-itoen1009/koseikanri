/*============================================================================
* �t�@�C���� : XxcsoSpDecisionPropertyUtils
* �T�v����   : ���̋@�ݒu�_����o�^ �o�^��񔽉f���[�e�B���e�B�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-02-02 1.0  SCS�������l  �V�K�쐬
* 2009-05-25 1.1  SCS�������l  [ST��QT1_1136]LOVPK���ڐݒ�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.util;

import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractManagementFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractManagementFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoPageRenderVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoPageRenderVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.util.XxcsoContractRegistConstants;

/*******************************************************************************
 * ���̋@�ݒu�_����o�^ �o�^��񔽉f���[�e�B���e�B�N���X�B
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractRegistReflectUtils 
{

  /*****************************************************************************
   * ���������e���f�B
   * @param pageRndrVo  �y�[�W�����ݒ�r���[�C���X�^���X
   * @param mngVo       �_��Ǘ��e�[�u�����r���[�C���X�^���X
   *****************************************************************************
   */
  public static void reflectInstallInfo(
    XxcsoPageRenderVOImpl                pageRndrVo
   ,XxcsoContractManagementFullVOImpl    mngVo
  )
  {
    // ***********************************
    // �f�[�^�s���擾
    // ***********************************
    XxcsoPageRenderVORowImpl pageRndrVoRow
      = (XxcsoPageRenderVORowImpl) pageRndrVo.first(); 

    XxcsoContractManagementFullVORowImpl mngVoRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first();

    // ///////////////////////////////////
    // �I�[�i�[�ύX�`�F�b�N�{�b�N�X�̒l�ɂ��l�𐧌�
    // //////////////////////////////////
    // �����R�[�h
    if ( ! XxcsoContractRegistConstants.OWNER_CHANGE_FLAG_ON.equals(
            pageRndrVoRow.getOwnerChangeFlag()
         ) 
    )
    {
      mngVoRow.setInstallCode(null);
// 2009-05-25 [ST��QT1_1136] Add Start
      mngVoRow.setInstanceId(null);
// 2009-05-25 [ST��QT1_1136] Add End
    }
  }

}