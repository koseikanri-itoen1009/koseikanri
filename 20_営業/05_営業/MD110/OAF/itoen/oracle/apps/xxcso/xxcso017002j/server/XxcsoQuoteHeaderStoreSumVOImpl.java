/*============================================================================
* �t�@�C���� : XxcsoQuoteHeaderStoreSumVOImpl
* �T�v����   : ���σw�b�_�ēǍ��ݗp�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-09 1.0  SCS�y���  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/*******************************************************************************
 * ���σw�b�_�����ēǍ��݂��邽�߂̃r���[�N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */

public class XxcsoQuoteHeaderStoreSumVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteHeaderStoreSumVOImpl()
  {
  }
  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param quoteHeaderId ���σw�b�_�[ID
   *****************************************************************************
   */
  public void initQuery(
    String quoteHeaderId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, quoteHeaderId);

    executeQuery();

  }
}