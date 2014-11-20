/*============================================================================
* ファイル名 : XxcsoRouteManagementUtils
* 概要説明   : 【アドオン：営業・営業領域】ルート管理共通ユーティリティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-05 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.util;

import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;
import java.sql.SQLException;

/*******************************************************************************
 * アドオン：ルート管理共通ユーティリティクラス
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRouteManagementUtils 
{
  private Object SYNC_OBJECT = new Object();
  private static XxcsoRouteManagementUtils _instance = null;

  /*****************************************************************************
   * 売上計画トランザクション初期化
   * @param txn           OADBTransactionインスタンス
   * @param baseCode      拠点コード
   * @param accountNumber 顧客コード
   * @param planYear      計画年
   * @param planYear      計画月
   *****************************************************************************
   */
  public void initTransaction(
    OADBTransaction  txn
   ,String           baseCode
   ,String           accountNumber
   ,String           planYear
   ,String           planMonth
  )
  {
    StringBuffer sql = new StringBuffer(100);
    int index = 0;
    sql.append("BEGIN");
    sql.append("  xxcso_rsrc_sales_plans_pkg.init_transaction(");
    sql.append("    iv_base_code      => :").append(++index);
    sql.append("   ,iv_account_number => :").append(++index);
    sql.append("   ,iv_year_month     => :").append(++index);
    sql.append("   ,ov_errbuf         => :").append(++index);
    sql.append("   ,ov_retcode        => :").append(++index);
    sql.append("   ,ov_errmsg         => :").append(++index);
    sql.append("  );");
    sql.append("END;");

    OracleCallableStatement stmt = null;
    try
    {
      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      index = 0;
      stmt.setString(++index, baseCode);
      stmt.setString(++index, accountNumber);
      stmt.setString(++index, (planYear + planMonth));

      int outIndex = index;
      
      stmt.registerOutParameter(++index, OracleTypes.VARCHAR);
      stmt.registerOutParameter(++index, OracleTypes.VARCHAR);
      stmt.registerOutParameter(++index, OracleTypes.VARCHAR);
      
      stmt.execute();

      String errorBuffer  = stmt.getString(++outIndex);
      String errorCode    = stmt.getString(++outIndex);
      String errorMessage = stmt.getString(++outIndex);
    }
    catch ( SQLException e )
    {
      throw
        XxcsoMessage.createSqlErrorMessage(
          e,
          XxcsoConstants.TOKEN_VALUE_INIT_ACCT_SALES_TXN
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
      catch ( SQLException e )
      {
      }
    }
  }

  /*****************************************************************************
   * 売上計画(複数顧客)トランザクション初期化
   * @param txn             OADBTransactionインスタンス
   * @param baseCode        拠点コード
   * @param employeeNumber  従業員番号
   * @param targetYear      対象年
   * @param targetYear      対象月
   *****************************************************************************
   */
  public void initTransactionBulk(
    OADBTransaction  txn
   ,String           baseCode
   ,String           employeeNumber
   ,String           targetYear
   ,String           targetMonth
  )
  {
    StringBuffer sql = new StringBuffer(100);
    int index = 0;
    sql.append("BEGIN");
    sql.append("  xxcso_rsrc_sales_plans_pkg.init_transaction_bulk(");
    sql.append("    iv_base_code       => :").append(++index);
    sql.append("   ,iv_employee_number => :").append(++index);
    sql.append("   ,iv_year_month      => :").append(++index);
    sql.append("   ,ov_errbuf          => :").append(++index);
    sql.append("   ,ov_retcode         => :").append(++index);
    sql.append("   ,ov_errmsg          => :").append(++index);
    sql.append("  );");
    sql.append("END;");

    OracleCallableStatement stmt = null;
    try
    {
      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      index = 0;
      stmt.setString(++index, baseCode);
      stmt.setString(++index, employeeNumber);
      stmt.setString(++index, (targetYear + targetMonth));

      int outIndex = index;
      
      stmt.registerOutParameter(++index, OracleTypes.VARCHAR);
      stmt.registerOutParameter(++index, OracleTypes.VARCHAR);
      stmt.registerOutParameter(++index, OracleTypes.VARCHAR);
      
      stmt.execute();

      String errorBuffer  = stmt.getString(++outIndex);
      String errorCode    = stmt.getString(++outIndex);
      String errorMessage = stmt.getString(++outIndex);
    }
    catch ( SQLException e )
    {
      throw
        XxcsoMessage.createSqlErrorMessage(
          e,
          XxcsoConstants.TOKEN_VALUE_INIT_ACCT_SALES_TXN
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
      catch ( SQLException e )
      {
      }
    }
  }

  /*****************************************************************************
   * ルート管理トランザクションコミット
   * @param txn           OADBTransactionインスタンス
   *****************************************************************************
   */
  public void commitTransaction(
    OADBTransaction txn
  )
  {
    synchronized( SYNC_OBJECT )
    {
      txn.commit();
    }
  }

  /*****************************************************************************
   * ルート管理共通ユーティリティインスタンス取得
   *****************************************************************************
   */
  public static XxcsoRouteManagementUtils getInstance()
  {
    return _instance;
  }
  
  /*****************************************************************************
   * ルート管理共通ユーティリティインスタンス初期化
   *****************************************************************************
   */
  static
  {
    _instance = new XxcsoRouteManagementUtils();
  }
  
  /*****************************************************************************
   * デフォルトコンストラクタ
   *****************************************************************************
   */
  private XxcsoRouteManagementUtils()
  {
  }
}