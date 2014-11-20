/*============================================================================
* ファイル名 : XxcsoAcctSalesPlansUtils
* 概要説明   : 訪問・売上計画画面　共通ユーティリティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS朴邦彦　  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.util;

import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleStatement;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleTypes;
import oracle.jbo.domain.Date;
import java.sql.SQLException;
import oracle.sql.DATE;

public class XxcsoAcctSalesPlansUtils 
{
  /*****************************************************************************
   * 売上計画トランザクション初期化
   * 
   * @param txn             OADBTransaction
   * @param baseCode        拠点コード
   * @param accountNumber   顧客コード
   * @param planYear        計画年
   * @param planMonth       計画月
   *****************************************************************************
   */
  public static void initTransaction(
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
    sql.append("  xxcso_acct_sales_plans_pkg.init_transaction(");
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
   * オンライン日付取得
   * @param txn         OADBTransaction
   *****************************************************************************
   */
  public static Date getOnlineSysdate(
    OADBTransaction  txn
  )
  {
    StringBuffer sql = new StringBuffer(100);
    sql.append("SELECT xxcso_util_common_pkg.get_online_sysdate AS now_date");
    sql.append("  FROM DUAL");

    OracleStatement stmt = null;
    OracleResultSet rslt = null;
    DATE nowDate = null;
    try
    {
      stmt
        = (OracleStatement)
            txn.createStatement(0);
      rslt
        = (OracleResultSet)
            stmt.executeQuery(sql.toString());
      if ( rslt.next() )
      {
        nowDate = rslt.getDATE("NOW_DATE");
        
      }
    }
    catch ( SQLException e )
    {
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
          ,"getOnlineSysdate"
        );
    }
    finally
    {
      try
      {
        if ( rslt != null )
        {
          rslt.close();
        }
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
      }
    }

    return new Date(nowDate);
  }

  /*****************************************************************************
   * オンライン年月の１日取得
   * @param txn         OADBTransaction  txn
   *****************************************************************************
   */
  public static Date getOnlineSysdateFirst(
    OADBTransaction  txn
  )
  {
    StringBuffer sql = new StringBuffer(100);
    sql.append("SELECT TRUNC(");
    sql.append("         xxcso_util_common_pkg.get_online_sysdate");
    sql.append("        ,'MM'");
    sql.append("       ) AS now_date");
    sql.append("  FROM DUAL");

    OracleStatement stmt = null;
    OracleResultSet rslt = null;
    DATE nowDate = null;
    try
    {
      stmt
        = (OracleStatement)
            txn.createStatement(0);
      rslt
        = (OracleResultSet)
            stmt.executeQuery(sql.toString());
      if ( rslt.next() )
      {
        nowDate = rslt.getDATE("NOW_DATE");
        
      }
    }
    catch ( SQLException e )
    {
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
          ,"getOnlineSysDateFirst"
        );
    }
    finally
    {
      try
      {
        if ( rslt != null )
        {
          rslt.close();
        }
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
      }
    }

    return new Date(nowDate);
  }

  /*****************************************************************************
   * システム日時の取得
   * @param txn         OADBTransaction  txn
   *****************************************************************************
   */
  public static String getSysdateTimeString(
    OADBTransaction  txn
  )
  {
    StringBuffer sql = new StringBuffer(100);
    sql.append("SELECT TO_CHAR(");
    sql.append("         SYSDATE");
    sql.append("        ,'YYYYMMDDHH24MISS'");
    sql.append("       ) AS now_date");
    sql.append("  FROM DUAL");

    OracleStatement stmt = null;
    OracleResultSet rslt = null;
    String nowDate = "";
    try
    {
      stmt
        = (OracleStatement)
            txn.createStatement(0);
      rslt
        = (OracleResultSet)
            stmt.executeQuery(sql.toString());
      if ( rslt.next() )
      {
        nowDate = rslt.getString("NOW_DATE");
        
      }
    }
    catch ( SQLException e )
    {
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
          ,"getSysdateTimeString"
        );
    }
    finally
    {
      try
      {
        if ( rslt != null )
        {
          rslt.close();
        }
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
      }
    }

    return nowDate;
  }

  /*****************************************************************************
   * 営業員判定
   *****************************************************************************
   */
  public static boolean isSalesPerson(
    OADBTransaction  txn
  )
  {
    StringBuffer sql = new StringBuffer(100);
    sql.append("SELECT xxcso_util_common_pkg.chk_responsibility(");
    sql.append("         fnd_global.user_id");
    sql.append("        ,fnd_global.resp_id");
    sql.append("        ,'1') AS readonly_value");
    sql.append("  FROM DUAL");

    OracleStatement stmt = null;
    OracleResultSet rslt = null;
    String readonlyValue = null;
    try
    {
      stmt
        = (OracleStatement)
            txn.createStatement(0);
      rslt
        = (OracleResultSet)
            stmt.executeQuery(sql.toString());
      if ( rslt.next() )
      {
        readonlyValue = rslt.getString(1);
      }
    }
    catch ( SQLException e )
    {
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
          ,"isSalesPerson"
        );
    }
    finally
    {
      try
      {
        if ( rslt != null )
        {
          rslt.close();
        }
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
      }
    }

    if ( "TRUE".equals(readonlyValue) )
    {
      return true;
    }
    return false;
  }

}