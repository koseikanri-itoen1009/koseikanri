/*============================================================================
* �t�@�C���� : XxpoShipToHeaderVOImpl
* �T�v����   : ���Ɏ��ѓ��̓w�b�_�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-01 1.0  �V���`��     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo442001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
 /***************************************************************************
  * ���Ɏ��ѓ��̓w�b�_�r���[�I�u�W�F�N�g�N���X�ł��B
  * @author  ORACLE �V�� �`��
  * @version 1.0
  ***************************************************************************
  */
 public class XxpoShipToHeaderVOImpl extends OAViewObjectImpl 
 {
   /**
    * 
    * This is the default constructor (do not remove)
    */
  public XxpoShipToHeaderVOImpl()
  { 
    
  } // �R���X�g���N�^
   
 /*****************************************************************************
  * VO�̏��������s���܂��B
  * @param reqNo - �˗�No
  *****************************************************************************
  */
  public void initQuery(String reqNo)
  {
    // ������
    setWhereClauseParams(null);
    setWhereClauseParam(0, reqNo);
    // �������s
    executeQuery();
  }
}