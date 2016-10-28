% Check from R:
%  news(db = tools:::.build_news_db_from_package_NEWS_Rd("~/R/Pkgs/cluster/inst/NEWS.Rd"))!
\name{NEWS}
\title{News for \R Package \pkg{cluster}}% MM: look into ../svn-log-from.all
\encoding{UTF-8}
\newcommand{\CRANpkg}{\href{http://CRAN.R-project.org/package=#1}{\pkg{#1}}}
%% NB: The date (yyyy-mm-dd) is the "Packaged:" date in ../DESCRIPTION

%% \section{Changes in a future version ...}{
%%   \subsection{New Features}{
%%     \itemize{
%%       \item __TODO__ \code{clusGap()} further gets new options
%%       as alternative to the PCA rotation
%%       and another one for specifying alternative distributions than the
%%       uniform on the hyper rectangle of the (rotated) data.
%%     }
%%   }
%% }

\section{Changes in version 2.0.4 (2016-04-15, svn r....)}{
  \subsection{New Features}{
    \itemize{
      \item \code{clusGap()} gets a new option \code{d.power = 1}
      allowing to choose the basic weight statistic as it was originally
      proposed, namely \emph{squared} distances by setting \code{d.power = 2}.
      %% ~/R/MM/Pkg-ex/cluster/Gonzalez-on-clusGap.R <--
    }
  }
  \subsection{Bug Fixes}{
    \itemize{
      \item fix small glitch in silhouette's help page.

      \item Finally fixed a bug (in the original Fortran code from
      Rousseeuw!) in clara's distance computation when there are
      \code{NA}s in the data.  As the fix is not backward compatible,
      a warning is produced (for the time being) if there \emph{are}
      \code{NA}s and the user does not explicitly use \code{clara(*, correct.d = TRUE)}.
    }
  }
}

\section{Changes in version 2.0.3 (2015-07-20, svn r6985)}{
  \subsection{New Features}{
    \itemize{
      \item This new \file{NEWS.Rd} file -- going to replace \file{ChangeLog}
      eventually.
    }
  }
  \subsection{Bug Fixes}{
    \itemize{
      \item import all we need (but not more) from the "base" pkgs
      (stats, graphics, ...).
    }
  }
}

\section{Changes in version 2.0.2 (2015-06-18, svn r6955)}{
  \subsection{New Features}{
    \itemize{
      \item using new \code{anyNA()} where appropriate.
      \item New Korean translations, thanks to Chel Hee Lee.
      \item \code{plotpart()}: \code{cmdscale()} tweaks.
    }
  }
  \subsection{Bug Fixes}{
    \itemize{
      \item valgrind detected missing allocation (\code{nisol["1"]} for k=1).
      \item typo R/daisy.q (R bug %once we require R >= 3.2.0: \PR{16430}
      \Sexpr[results=rd]{tools:::Rd_expr_PR(16430)}).
    }
  }
}

\section{Changes in version 2.0.1 (2015-01-31, svn r6877)}{
  \subsection{Bug Fixes}{
    \itemize{
      \item Fix \code{silhouette( obj )} for \code{obj <- pam(x, k = 1)}.
    }
  }
}

\section{Changes in version 2.0.0 (2015-01-29, svn r6874)}{
  \subsection{New Features}{
    \itemize{
      \item \code{pam()} now using \code{.Call()} instead of
      \code{.C()} is potentially considerably more efficient.
      \item \code{agnes()} has improved \code{trace} behaviour; also,
      some invalid \code{par.method = *} settings now give an early and
      understandable error message.
      \item \code{lower.to.upper.tri.inds()} (etc) now returns \code{integer}.
    }
  }
  \subsection{Bug Fixes}{
    \itemize{
      \item \code{.C(..)} and \code{.Fortran(..)}: no longer using
      \code{DUP=FALSE} as that has become deprecated.
    }
  }
}

\section{Changes in version 1.15.3 (2014-09-04, svn r6804)}{
  \subsection{New Features}{
    \itemize{
      \item \code{agnes()} and \code{diana()} finally get, respectively
      work with a \code{trace.lev} option.
      \item \code{plot.(agnes|diana)()} now deals well with long
      \code{call}s, by using multiple title lines.
      \item Message translations now also for C level error messages.
    }
  }
  \subsection{Bug Fixes}{
    \itemize{
      \item \code{agnes(*, method="flexible", par.method = c(a1, a2, b, c))},
      i.e., \code{length(alpha) == 4}, finally works \emph{correctly}.
    }
  }
}

\section{Changes in version 1.15.2 (2014-03-31, svn r6724)}{
  \subsection{New Features}{
    \itemize{
      \item Rewrote parts of the R level messages so they are more
      easily translatable, thanks to proposals by Lukasz Daniel.
      \item French translations from Philippe Grosjean.
    }
  }
}

\section{Changes in version 1.15.1 (2014-03-13, svn r6676)}{
  \subsection{Bug Fixes}{
    \itemize{
      \item \code{mona} example not working in \R < 3.0.x.
    }
  }
}

\section{Changes in version 1.15.0 (2014-03-11, svn r6672)}{
  \subsection{New Features}{
    \itemize{
      \item \code{agnes(*, method = "gaverage")} contributed by Pierre
      Roudier.
      \item documentation improvements;
      \item better translatable messages and translation updates.
    }
  }
}


%% ============================== FIXME ===========================
%%        ~~~~~~~~~
%% use ../ChangeLog
%%        ~~~~~~~~~
%% and then
%%
%% use ../svn-log-from.all
%%        ~~~~~~~~~~~~~~~~
%% and ../../cluster_Archive.lst  {~= CRAN  src/contrib/Archive/cluster/ :
%%
\section{Changes in version 1.14.4 (2013-03-26, svn r....)}{
  \subsection{New Features}{
    \itemize{
      \item -
    }
  }
  \subsection{Bug Fixes}{
    \itemize{
      \item -
    }
  }
}

\section{Changes in version 1.14.3 (2012-10-14, svn r....)}{
  \subsection{New Features}{
    \itemize{
      \item Polnish translations from Lukasz Daniel.
    }
  }
  \subsection{Bug Fixes}{
    \itemize{
      \item -
    }
  }
}


\section{Changes in version 1.14.2 (2012-02-06, svn r....)}{
  \subsection{New Features}{
    \itemize{
      \item New \code{clusGap()} to compute the \dQuote{cluster Gap}
      goodness-of-fit statistic.
    }
  }
  \subsection{Bug Fixes}{
    \itemize{
      \item -
    }
  }
}

\section{Changes in version 1.14.1 (2011-10-16, svn r....)}{
  \subsection{New Features}{
    \itemize{
      \item First translations (into German, thanks to Detlef Steuer).
      \item better \code{citation("cluster")}
    }
  }
  \subsection{Bug Fixes}{
    \itemize{
      \item \code{plot.silhouette(..., col = <one per cluster>)} had
      ordering bug.
    }
  }
}


%%  253036  Mar 26  2013   cluster_1.14.4.tar.gz
%%  259743  Oct 14  2012   cluster_1.14.3.tar.gz
%%  250936  Feb  8  2012   cluster_1.14.2.tar.gz
%%  246438  Oct 17  2011   cluster_1.14.1.tar.gz
%%  226332  Jun  8  2011   cluster_1.14.0.tar.gz
%%  214765  Feb 21  2011   cluster_1.13.3.tar.gz
%%  213663  Nov 10  2010   cluster_1.13.2.tar.gz
%%  214083  Jun 25  2010   cluster_1.13.1.tar.gz
%%  214677  Apr  2  2010   cluster_1.12.3.tar.gz
%%  214577  Oct  6  2009   cluster_1.12.1.tar.gz
%%  215041  May 13  2009   cluster_1.12.0.tar.gz

%% ============================== FIXME ===========================



%% \section{Version 0.2-4}{
%% \subsection{..., 0.3-1, 0.3-n (n=3,5,...,26): 22 more CRAN releases}{
%%   \itemize{ \item ............................................. } }}

% How can I add vertical space ?
% \preformatted{} is not allowed, nor is \cr


\section{Version 1.2-0 (1999-04-11)}{
  \subsection{First CRAN release of the \pkg{cluster} package, by Kurt Hornik}{
    \itemize{
      \item Martin Maechler had its own version independently.
      \item Both closely modeled after \code{clus} the tarball off JSS.
  }}

  \subsection{R Functions -- Fortran Files}{
    \itemize{
      \item \code{agnes()} -- \file{twins.f} for the \dQuote{twins} \code{agnes} and \code{diana}.
      \item \code{clara()} -- \code{clara.f}
      \item \code{daisy()} -- \file{daisy.f} (and \file{meet.f})
      \item \code{diana()} -- (twins.f)
      \item \code{fanny()} -- \file{fanny.f}
      \item \code{mona()}  -- \file{mona.f}
      \item \code{pam()}   -- \file{pam.f}
    }
  }
  \subsection{Data Sets}{
    \itemize{
      \item agriculture
      \item animals
      \item flower
      \item ruspini
      \item votes.repub
    }
  }

  \subsection{Further Features}{
    \itemize{
      \item all Examples in \file{man/*.Rd} hand edited to become
      executable.
      \item \code{summary()}, \code{print()} (and
    \code{print.summary.**()} methods) for the six basic \R functions above.
    }
  }
}



\section{Version 1.1-2 (1998-06-16)}{
  \subsection{Renamed previous \pkg{clus} to \pkg{cluster}}{
    \itemize{ \item . }
  }
}
\section{Version 1.1-1 (1998-06-15)}{
  \subsection{New Features}{
    \itemize{
      \item started \file{ChangeLog}
    }
  }
}

