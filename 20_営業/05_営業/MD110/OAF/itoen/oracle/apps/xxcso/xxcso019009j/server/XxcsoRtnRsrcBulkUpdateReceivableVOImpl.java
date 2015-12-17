/*============================================================================
* �t�@�C���� : XxcsoRtnRsrcBulkUpdateReceivableVOImpl
* �T�v����   : �������_�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2015-09-08 1.0  SCSK�ː��a�K  [E_�{�ғ�_13307]�V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/*******************************************************************************
 * �������_�̃r���[�N���X�ł��B
 * @author  SCSK�ː��a�K
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcBulkUpdateReceivableVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRtnRsrcBulkUpdateReceivableVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param AccountNumber       �ڋq�R�[�h
   * @param baseCode            ���_�R�[�h
   *****************************************************************************
   */
  public void initQuery(
    String AccountNumber
   ,String baseCode
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, AccountNumber);
    setWhereClauseParam(1, baseCode);

    executeQuery();
  }
}