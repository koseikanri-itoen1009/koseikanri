/*============================================================================
* �t�@�C���� : XxpoShippedMakeHeaderVOImpl
* �T�v����   : �o�Ɏ��ѓ��̓w�b�_�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-28 1.0  �R�{���v     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo441001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * �o�Ɏ��ѓ��̓w�b�_�r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  ORACLE �R�{ ���v
 * @version 1.0
 ***************************************************************************
 */
public class XxpoShippedMakeHeaderVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoShippedMakeHeaderVOImpl()
  {
  }
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param reqNo - �˗�No
   ****************************************************************************/
  public void initQuery(String reqNo)
  {
    setWhereClauseParam(0, reqNo);
    // �������s
    executeQuery();
  }
}