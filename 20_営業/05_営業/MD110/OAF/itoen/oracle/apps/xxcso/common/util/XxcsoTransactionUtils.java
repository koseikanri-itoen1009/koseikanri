/*============================================================================
* �t�@�C���� : XxcsoTransactionUtils
* �T�v����   : �y�A�h�I���F�c�ƁE�c�Ɨ̈�z���ʃg�����U�N�V�������[�e�B���e�B�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-02-06 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.util;

import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import java.sql.CallableStatement;
import java.sql.SQLException;

/*******************************************************************************
 * �A�h�I���F���ʃg�����U�N�V�������[�e�B���e�B�N���X
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoTransactionUtils 
{
  /*****************************************************************************
   * ���W���[���ݒ�
   * @param txn           OADBTransaction�C���X�^���X
   * @param amClassName   �N���X���iobject.getClass().getName()�j
   *****************************************************************************
   */
  public static void setModule(
    OADBTransaction txn
   ,String          amClassName
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    StringBuffer sql = new StringBuffer(100);
    sql.append("BEGIN");
    sql.append("  xxcso_009002j_pkg.init_transaction(");
    sql.append("    iv_class_name => :1");
    sql.append("  );");
    sql.append("END;");

    CallableStatement stmt = null;
    
    try
    {
      XxcsoUtils.debug(txn, amClassName);

      stmt = txn.createCallableStatement(sql.toString(), 0);

      stmt.setString(1, amClassName);

      stmt.execute();
    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw XxcsoMessage.createSqlErrorMessage(
        sqle
       ,XxcsoConstants.TOKEN_VALUE_SET_MODULE
      );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException sqle )
      {
        XxcsoUtils.unexpected(txn, sqle);
      }
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }
}