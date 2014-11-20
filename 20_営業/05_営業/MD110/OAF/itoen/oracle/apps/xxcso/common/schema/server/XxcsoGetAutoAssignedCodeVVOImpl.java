/*============================================================================
* �t�@�C���� : XxcsoGetAutoAssignedCodeVVOImpl
* �T�v����   : �����̔ԃR�[�h�擾�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS����_     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * �����̔Ԃ��ꂽ�R�[�h���擾���邽�߂̃r���[�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoGetAutoAssignedCodeVVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoGetAutoAssignedCodeVVOImpl()
  {
  }

  public void initQuery(
    String assignClass
   ,String baseCode
   ,Date   currentDate
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, assignClass);
    setWhereClauseParam(1, baseCode);
    setWhereClauseParam(2, currentDate);

    executeQuery();
  }
}