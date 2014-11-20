/*============================================================================
* �t�@�C���� : XxinvMovementResultsHdVOImpl
* �T�v����   : ���o�Ɏ��уw�b�_:�����r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-13 1.0  �勴�F�Y     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv510001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * �����r���[�I�u�W�F�N�g�ł��B
 * @author  ORACLE �勴 �F�Y
 * @version 1.0
 ***************************************************************************
 */

public class XxinvMovementResultsHdVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxinvMovementResultsHdVOImpl()
  {
  }

  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param searchHdrId �����p�����[�^�w�b�_ID
   ****************************************************************************/
  public void initQuery(
    String  searchHdrId         // �����p�����[�^�w�b�_ID
   )
  {
    // ������
    setWhereClauseParams(null);

    // WHERE��̃o�C���h�ϐ��Ɍ����l���Z�b�g
    setWhereClauseParam(0, searchHdrId);

    // SELECT�����s
    executeQuery();
  }
}