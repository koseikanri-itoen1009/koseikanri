/*============================================================================
* �t�@�C���� : XxcsoAsLeadVVOImpl
* �T�v����   : ���k���擾�r���[�N���X
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
import oracle.jbo.domain.Number;

/*******************************************************************************
 * ���k�����擾���邽�߂̃r���[�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAsLeadVVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAsLeadVVOImpl()
  {
  }

  public void initQuery(
    Number leadId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, leadId);

    executeQuery();
  }
}